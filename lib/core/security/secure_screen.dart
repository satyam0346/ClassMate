import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Controls Android FLAG_SECURE on the current Activity window.
///
/// FLAG_SECURE prevents screenshots and screen recording on sensitive screens
/// such as the Login screen and Profile screen.
///
/// Only effective on Android. No-ops on other platforms or if the
/// platform channel fails — this must never crash the app.
class SecureScreen {
  SecureScreen._();

  static const _channel = MethodChannel('com.classmate.app/secure_screen');

  /// Enable FLAG_SECURE — call this in initState() of sensitive screens.
  static Future<void> enable() async {
    if (!defaultTargetPlatform.isAndroid) return;
    try {
      await _channel.invokeMethod('enable');
    } catch (e) {
      debugPrint('[SecureScreen] enable failed (non-fatal): $e');
    }
  }

  /// Disable FLAG_SECURE — call this in dispose() of sensitive screens.
  static Future<void> disable() async {
    if (!defaultTargetPlatform.isAndroid) return;
    try {
      await _channel.invokeMethod('disable');
    } catch (e) {
      debugPrint('[SecureScreen] disable failed (non-fatal): $e');
    }
  }
}

extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
