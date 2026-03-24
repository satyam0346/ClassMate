import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps connectivity_plus and exposes a boolean online/offline stream.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();

  /// Stream of boolean values: true = online, false = offline.
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map((results) => _isOnline(results));

  /// Check connectivity right now (one-time, async).
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi   ||
        r == ConnectivityResult.ethernet);
  }
}

// ── Riverpod Providers ────────────────────────────────────────

/// Stream provider: true = online, false = offline.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // Emit current state immediately
  yield await ConnectivityService.instance.isOnline;
  // Then stream changes
  yield* ConnectivityService.instance.onlineStream;
});

/// Convenience provider: simple bool, defaults to true (optimistic).
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).valueOrNull ?? true;
});
