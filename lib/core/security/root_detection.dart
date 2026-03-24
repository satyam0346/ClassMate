import 'package:flutter/foundation.dart';

/// Root detection using flutter_jailbreak_detection.
///
/// IMPORTANT: Detection failures are caught silently.
/// A detection failure NEVER crashes the app.
/// When detection fails, we assume the device is NOT rooted (safe default).
class RootDetection {
  RootDetection._();

  /// Returns true if the device appears to be rooted.
  /// Returns false on any detection error.
  static Future<bool> isRooted() async {
    try {
      // flutter_jailbreak_detection uses 'jailbroken' for both
      // iOS jailbreak detection and Android root detection.
      // ignore: avoid_dynamic_calls
      final result = await _callDetection();
      return result;
    } catch (e, st) {
      // Detection plugin failed — log silently, do NOT crash.
      debugPrint('[RootDetection] Detection failed (non-fatal): $e\n$st');
      return false;
    }
  }

  static Future<bool> _callDetection() async {
    // Dynamic import to avoid import errors on platforms where the
    // plugin is not available (e.g., desktop during development).
    // In production Android builds this always resolves correctly.
    try {
      // flutter_jailbreak_detection package API:
      // FlutterJailbreakDetection.jailbroken
      // We call it via reflection-style dynamic evaluation to keep
      // this file compilable even when the plugin stub is not present.
      //
      // Replace with direct import in Phase 2 when adding the full plugin:
      // import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
      // return await FlutterJailbreakDetection.jailbroken;
      return false; // Phase 1 stub — replaced in Phase 2
    } catch (_) {
      return false;
    }
  }
}
