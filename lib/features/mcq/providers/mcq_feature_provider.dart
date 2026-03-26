import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/remote_config_service.dart';

/// Exposes Remote Config feature flags as Riverpod providers.
/// These can be updated in the Firebase Console and take effect
/// the next time the app is opened — NO app update required.

/// Whether the BES MCQ Practice feature is visible in the app.
/// Default: false — flip to true in Firebase Remote Config console.
final mcqFeatureEnabledProvider = Provider<bool>((ref) {
  return RemoteConfigService.instance.mcqBesEnabled;
});
