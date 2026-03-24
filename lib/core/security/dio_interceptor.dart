import 'package:flutter/foundation.dart';

/// Emulator/AVD detection.
///
/// IMPORTANT: Detection failures are caught silently.
/// A detection failure NEVER crashes the app.
/// When detection fails, we assume the device is NOT an emulator (safe default).
class EmulatorDetection {
  EmulatorDetection._();

  /// Returns true if the app appears to be running on an emulator.
  /// Returns false on any detection error.
  static Future<bool> isEmulator() async {
    try {
      return await _detectEmulator();
    } catch (e, st) {
      debugPrint('[EmulatorDetection] Detection failed (non-fatal): $e\n$st');
      return false;
    }
  }

  static Future<bool> _detectEmulator() async {
    try {
      // Primary: flutter_jailbreak_detection exposes developerMode
      // which is a reliable emulator/AVD signal on Android.
      //
      // Phase 2 will wire this to:
      // import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
      // return await FlutterJailbreakDetection.developerMode;
      //
      // Fallback heuristics (Phase 2):
      // - device_info_plus: check DeviceInfoPlugin().androidInfo
      //   model contains 'sdk', brand is 'google', hardware is 'goldfish'
      return false; // Phase 1 stub — replaced in Phase 2
    } catch (_) {
      return false;
    }
  }
}
