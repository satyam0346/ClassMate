import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Handles Firebase Remote Config fetch and OTA update checks.
///
/// Called once on app boot (in main.dart) before the app renders.
/// All fetch errors are caught — app continues normally if Remote Config fails.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  late final FirebaseRemoteConfig _config;

  // ── Cached values after fetch ──────────────────────────────
  String  get appVersion      => _config.getString('app_version');
  String  get updateMessage   => _config.getString('update_message');
  bool    get forceUpdate     => _config.getBool('force_update');
  bool    get maintenanceMode => _config.getBool('maintenance_mode');
  String  get apkDownloadUrl  => _config.getString('apk_download_url');
  String  get allowedDomains  => _config.getString('allowed_email_domains');
  String  get superAdmins     => _config.getString('super_admins');

  // ── Feature flags ───────────────────────────────────────────
  /// Controls BES MCQ Practice visibility WITHOUT an app update.
  /// Set to true in Firebase Remote Config console to enable instantly.
  bool    get mcqBesEnabled   => _config.getBool('mcq_bes_enabled');

  /// Initialize Remote Config with defaults and fetch from server.
  Future<void> init() async {
    try {
      _config = FirebaseRemoteConfig.instance;

      // Set default values (used if fetch fails or on first run)
      await _config.setDefaults({
        'app_version':           '1.0.0',
        'update_message':        '',
        'force_update':          false,
        'maintenance_mode':      false,
        'apk_download_url':      '',
        'allowed_email_domains': '@marwadiuniversity.ac.in,@gmail.com',
        'super_admins':          '',
        // Feature flags — all OFF by default, toggle in Firebase Console
        'mcq_bes_enabled':       false,
      });

      // Cache expiry: 1 hour in production, 0 in debug for fast iteration
      await _config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout:      const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ));

      // Fetch and activate. If this fails, defaults above are used.
      await _config.fetchAndActivate();

      debugPrint('[RemoteConfig] Fetched. app_version=${appVersion}, '
          'force_update=$forceUpdate, maintenance=$maintenanceMode');
    } catch (e) {
      // Remote Config failure is NON-FATAL. App continues with defaults.
      debugPrint('[RemoteConfig] Fetch failed (non-fatal): $e');
    }
  }

  /// Compare Remote Config app_version with locally installed version.
  /// Returns true if the installed version is OLDER than required.
  Future<bool> isUpdateRequired() async {
    try {
      if (!forceUpdate) return false;
      final info = await PackageInfo.fromPlatform();
      final local    = _parseVersion(info.version);
      final required = _parseVersion(appVersion);
      return _isOlderThan(local, required);
    } catch (_) {
      return false;
    }
  }

  /// Parse a semver string like "1.2.3" into [1, 2, 3].
  List<int> _parseVersion(String version) {
    try {
      return version
          .split('.')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .toList();
    } catch (_) {
      return [0, 0, 0];
    }
  }

  /// Returns true if [local] version is strictly older than [required].
  bool _isOlderThan(List<int> local, List<int> required) {
    for (var i = 0; i < required.length && i < local.length; i++) {
      if (local[i] < required[i]) return true;
      if (local[i] > required[i]) return false;
    }
    return false;
  }

  /// Parse allowed email domains from Remote Config.
  /// Returns a list like ['@marwadiuniversity.ac.in', '@gmail.com'].
  List<String> getAllowedEmailDomains() {
    return allowedDomains
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();
  }
}
