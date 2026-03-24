import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Firebase Storage upload/download service.
/// Enforces file type and size limits before any upload.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _storage = FirebaseStorage.instance;

  // ── Blocked extensions (mirrors storage.rules) ────────────
  static const _blockedExtensions = {
    'exe', 'sh', 'apk', 'msi', 'bat', 'cmd',
    'ps1', 'vbs', 'jar', 'py', 'rb', 'php',
    'pl', 'lua', 'bin', 'dmg', 'iso', 'run',
  };

  static const int _profileMaxBytes   = 512 * 1024; // 512KB
  static const int _materialMaxBytes  = 50 * 1024 * 1024; // 50MB

  // ── Profile photo upload ──────────────────────────────────

  /// Compresses [file] then uploads to /profiles/{userId}/{filename}.
  /// Returns the public download URL.
  Future<String> uploadProfilePhoto({
    required String userId,
    required File   file,
    void Function(double progress)? onProgress,
  }) async {
    _validateExtension(file.path);

    // Compress before upload
    final compressed = await _compressImage(file);
    final bytes      = await compressed.readAsBytes();

    if (bytes.length > _profileMaxBytes) {
      throw Exception('Profile photo must be under 2MB after compression.');
    }

    final filename = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref      = _storage.ref('profiles/$userId/$filename');

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        final progress =
            snap.bytesTransferred / (snap.totalBytes == 0 ? 1 : snap.totalBytes);
        onProgress(progress);
      });
    }

    await task;
    return await ref.getDownloadURL();
  }

  // ── Material file upload ──────────────────────────────────

  /// Upload a material file to /materials/{filename}.
  /// Returns the download URL.
  Future<String> uploadMaterial({
    required File   file,
    required String title,
    void Function(double progress)? onProgress,
  }) async {
    _validateExtension(file.path);

    final bytes = await file.readAsBytes();
    if (bytes.length > _materialMaxBytes) {
      throw Exception('File must be under 50MB.');
    }

    final ext      = p.extension(file.path);
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$title$ext';
    final ref      = _storage.ref('materials/$filename');

    final task = ref.putData(bytes);

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        final progress =
            snap.bytesTransferred / (snap.totalBytes == 0 ? 1 : snap.totalBytes);
        onProgress(progress);
      });
    }

    await task;
    return await ref.getDownloadURL();
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('[Storage] deleteFile failed (non-fatal): $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  void _validateExtension(String path) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    if (_blockedExtensions.contains(ext)) {
      throw Exception('File type .$ext is not allowed.');
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir    = await getTemporaryDirectory();
      final target = '${dir.path}/thumbnail_${p.basename(file.path)}';
      
      // Aggressive downsampling to 400x400 for profile thumbnails
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality:   75,
        minWidth:  400,
        minHeight: 400,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('[Storage] Image compression failed (non-fatal): $e');
      return file;
    }
  }
}
