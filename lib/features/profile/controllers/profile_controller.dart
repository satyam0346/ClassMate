import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../shared/models/user_model.dart';

// ── State ─────────────────────────────────────────────────────

class ProfileEditState {
  final bool   isSaving;
  final double uploadProgress;
  final String? error;
  final bool   success;

  const ProfileEditState({
    this.isSaving        = false,
    this.uploadProgress  = 0,
    this.error,
    this.success         = false,
  });

  ProfileEditState copyWith({
    bool?   isSaving,
    double? uploadProgress,
    String? error,
    bool?   success,
  }) =>
      ProfileEditState(
        isSaving:       isSaving       ?? this.isSaving,
        uploadProgress: uploadProgress ?? this.uploadProgress,
        error:          error,
        success:        success        ?? this.success,
      );
}

// ── Provider ──────────────────────────────────────────────────

class ProfileController extends StateNotifier<ProfileEditState> {
  ProfileController() : super(const ProfileEditState());

  final _fs      = FirestoreService.instance;
  final _storage = StorageService.instance;
  final _picker  = ImagePicker();

  // ── Update profile text fields ────────────────────────────

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String classGroup,
    required String section,
    required String rollNo,
    required String grNumber,
    required String bio,
    required String gender,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final data = InputSanitizer.sanitizeMap({
        'name':       name,
        'phone':      phone,
        'classGroup': classGroup,
        'section':    section,
        'rollNo':     rollNo,
        'grNumber':   grNumber,
        'bio':        bio,
        'gender':     gender,
      });

      // Validate lengths
      if ((data['name'] as String).isEmpty) {
        throw Exception('Name cannot be empty.');
      }
      if ((data['name'] as String).length > 100) {
        throw Exception('Name must be under 100 characters.');
      }

      await _fs.set('users/$uid', {
        ...data,
        if (state.uploadProgress == 0) 'createdAt': FieldValue.serverTimestamp(),
      }, merge: true);
      state = state.copyWith(isSaving: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Pick & upload profile photo ───────────────────────────

  Future<void> uploadProfilePhoto(String uid) async {
    final picked = await _picker.pickImage(
      source:    ImageSource.gallery,
      maxWidth:  1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    state = state.copyWith(isSaving: true, uploadProgress: 0, error: null);
    try {
      final url = await _storage.uploadProfilePhoto(
        userId: uid,
        file:   File(picked.path),
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      await _fs.update('users/$uid', {'photoUrl': url});
      state = state.copyWith(isSaving: false, success: true, uploadProgress: 1);
    } catch (e) {
      state = state.copyWith(
          isSaving: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void resetState() => state = const ProfileEditState();
}

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileEditState>(
  (ref) => ProfileController(),
);

// ── Admin: stream all user profiles ──────────────────────────

final allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('name')
      .snapshots()
      .map((snap) =>
          snap.docs.map(UserModel.fromFirestore).toList());
});
