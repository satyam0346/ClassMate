import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../shared/models/material_model.dart';
import '../../../core/services/fcm_server_service.dart';

// ── Stream providers ──────────────────────────────────────────

/// All materials ordered by uploadedAt descending.
final allMaterialsProvider = StreamProvider<List<MaterialModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('materials')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(MaterialModel.fromFirestore).toList());
});

/// Distinct subjects from all materials — for filter chips.
final materialSubjectsProvider = Provider<List<String>>((ref) {
  final all      = ref.watch(allMaterialsProvider).valueOrNull ?? [];
  final subjects = all.map((m) => m.subject).toSet().toList()..sort();
  return subjects;
});

/// Currently selected subject filter (empty = "All").
final selectedSubjectProvider = StateProvider<String>((ref) => '');

/// Current search text.
final materialSearchProvider = StateProvider<String>((ref) => '');

/// Filtered materials based on selected subject AND search text.
final filteredMaterialsProvider = Provider<List<MaterialModel>>((ref) {
  final all      = ref.watch(allMaterialsProvider).valueOrNull ?? [];
  final selected = ref.watch(selectedSubjectProvider);
  final search   = ref.watch(materialSearchProvider).trim().toLowerCase();
  
  return all.where((m) {
    if (selected.isNotEmpty && m.subject != selected) return false;
    if (search.isNotEmpty && !m.title.toLowerCase().contains(search)) return false;
    return true;
  }).toList();
});

// ── Upload state ──────────────────────────────────────────────

class MaterialUploadState {
  final bool   isUploading;
  final double uploadProgress; // 0.0 – 1.0
  final String? error;
  final bool   success;

  const MaterialUploadState({
    this.isUploading     = false,
    this.uploadProgress  = 0,
    this.error,
    this.success         = false,
  });

  MaterialUploadState copyWith({
    bool?    isUploading,
    double?  uploadProgress,
    String?  error,
    bool?    success,
  }) =>
      MaterialUploadState(
        isUploading:    isUploading    ?? this.isUploading,
        uploadProgress: uploadProgress ?? this.uploadProgress,
        error:          error,
        success:        success        ?? this.success,
      );

  MaterialUploadState reset() => const MaterialUploadState();
}

// ── Controller ────────────────────────────────────────────────

class MaterialController extends StateNotifier<MaterialUploadState> {
  MaterialController() : super(const MaterialUploadState());

  final _fs      = FirestoreService.instance;
  final _storage = StorageService.instance;
  final _dio     = Dio();

  // ── Upload file ───────────────────────────────────────────

  Future<void> uploadFile({
    required File   file,
    required String title,
    required String subject,
    required String description,
    required String uploadedBy,
  }) async {
    state = state.copyWith(isUploading: true, error: null, uploadProgress: 0);
    try {
      final sanitizedTitle = InputSanitizer.sanitizeTitle(title);
      final ext            = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      final fileType       = _resolveFileType(ext);
      final fileSize       = await file.length();

      final url = await _storage.uploadMaterial(
        file:  file,
        title: sanitizedTitle,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      final ref = await _fs.add('materials', MaterialModel(
        id:          '',
        title:       sanitizedTitle,
        subject:     InputSanitizer.sanitizeText(subject),
        description: InputSanitizer.sanitizeDescription(description),
        fileType:    fileType,
        url:         url,
        fileName:    p.basename(file.path),
        fileSize:    fileSize,
        uploadedBy:  uploadedBy,
        uploadedAt:  DateTime.now(),
      ).toFirestore());

      state = state.copyWith(
          isUploading: false, uploadProgress: 1.0, success: true);

      // Send FCM directly from client using bundled Service Account (Serverless workaround)
      await FcmServerService.sendNotification(
        title: 'New Material: $sanitizedTitle',
        body:  'A new $fileType file has been uploaded for $subject.',
        topic: AppStrings.fcmTopicMaterials,
        data:  {'materialId': ref.id},
      );

    } catch (e) {
      state = state.copyWith(
          isUploading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Add link ──────────────────────────────────────────────

  Future<void> addLink({
    required String title,
    required String url,
    required String subject,
    required String description,
    required String uploadedBy,
  }) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final ref = await _fs.add('materials', MaterialModel(
        id:          '',
        title:       InputSanitizer.sanitizeTitle(title),
        subject:     InputSanitizer.sanitizeText(subject),
        description: InputSanitizer.sanitizeDescription(description),
        fileType:    'link',
        url:         url,
        fileName:    '',
        fileSize:    0,
        uploadedBy:  uploadedBy,
        uploadedAt:  DateTime.now(),
      ).toFirestore());

      state = state.copyWith(isUploading: false, success: true);

      // Send FCM directly from client using bundled Service Account (Serverless workaround)
      await FcmServerService.sendNotification(
        title: 'New Link: ${InputSanitizer.sanitizeTitle(title)}',
        body:  'A new link has been shared for $subject.',
        topic: AppStrings.fcmTopicMaterials,
        data:  {'materialId': ref.id},
      );

    } catch (e) {
      state = state.copyWith(
          isUploading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteMaterial(MaterialModel material) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      // Delete from storage only if it's a real uploaded file
      if (!material.isLink && material.url.isNotEmpty) {
        await _storage.deleteFile(material.url);
      }
      await _fs.delete('materials/${material.id}');
      state = state.copyWith(isUploading: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isUploading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  String _resolveFileType(String ext) {
    const pdfExts   = {'pdf'};
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'};
    const docExts   = {'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'odt', 'csv'};

    if (pdfExts.contains(ext))   return 'pdf';
    if (imageExts.contains(ext)) return 'image';
    if (docExts.contains(ext))   return 'doc';
    return 'other';
  }

  // ── Client-side FCM ───────────────────────────────────────
  // Note: Push notifications are explicitly sent from the device 
  // without a backend to accommodate Spark plan constraints.

  void resetState() => state = state.reset();
}

final materialControllerProvider =
    StateNotifierProvider.autoDispose<MaterialController, MaterialUploadState>(
  (_) => MaterialController(),
);
