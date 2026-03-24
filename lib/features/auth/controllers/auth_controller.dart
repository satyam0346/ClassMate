import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../shared/models/user_model.dart';

// ── Rate Limit State ──────────────────────────────────────────

class RateLimitState {
  final int       failedAttempts;
  final DateTime? lockoutEndTime;

  const RateLimitState({
    this.failedAttempts = 0,
    this.lockoutEndTime,
  });

  bool get isLockedOut =>
      lockoutEndTime != null && DateTime.now().isBefore(lockoutEndTime!);

  Duration get remaining =>
      isLockedOut ? lockoutEndTime!.difference(DateTime.now()) : Duration.zero;

  int get secondsRemaining => remaining.inSeconds;

  RateLimitState copyWith({int? failedAttempts, DateTime? lockoutEndTime}) =>
      RateLimitState(
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lockoutEndTime: lockoutEndTime ?? this.lockoutEndTime,
      );

  RateLimitState reset() =>
      const RateLimitState(failedAttempts: 0, lockoutEndTime: null);
}

class RateLimitNotifier extends StateNotifier<RateLimitState> {
  RateLimitNotifier() : super(const RateLimitState());

  static const int _maxAttempts    = 5;
  static const int _lockoutSeconds = 60;

  Timer? _tickTimer;

  void recordFailure() {
    final attempts = state.failedAttempts + 1;
    if (attempts >= _maxAttempts) {
      final lockoutEnd =
          DateTime.now().add(const Duration(seconds: _lockoutSeconds));
      state = state.copyWith(
        failedAttempts: attempts,
        lockoutEndTime: lockoutEnd,
      );
      _startTicker();
    } else {
      state = state.copyWith(failedAttempts: attempts);
    }
  }

  void reset() {
    _tickTimer?.cancel();
    state = state.reset();
  }

  /// Ticks every second so the UI countdown rebuilds smoothly.
  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isLockedOut) {
        reset();
      } else {
        // Trigger a rebuild by emitting a copy (same lockout, updated remaining)
        state = RateLimitState(
          failedAttempts: state.failedAttempts,
          lockoutEndTime: state.lockoutEndTime,
        );
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}

final rateLimitProvider =
    StateNotifierProvider.autoDispose<RateLimitNotifier, RateLimitState>(
  (ref) => RateLimitNotifier(),
);

// ── Auth Controller ───────────────────────────────────────────

/// Thin controller layer wrapping AuthService.
/// Handles:
///  - Rate limiting through RateLimitNotifier
///  - Input sanitization before any Firestore write
///  - Domain validation (client-side gate)
///  - Consistent error message normalization
class AuthController {
  final Ref _ref;
  AuthController(this._ref);

  // ── Login ───────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    final rateLimit = _ref.read(rateLimitProvider.notifier);
    final state     = _ref.read(rateLimitProvider);

    if (state.isLockedOut) {
      throw Exception(
          'Too many failed attempts. Try again in ${state.secondsRemaining}s.');
    }

    // Client-side domain check before any network call
    final domainError = AppValidators.emailDomain(email);
    if (domainError != null) throw Exception(domainError);

    try {
      await AuthService.instance.signIn(email.trim(), password);
      rateLimit.reset(); // Reset on success
    } on FirebaseAuthException catch (e) {
      rateLimit.recordFailure();
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Login with Google ───────────────────────────────────────
  Future<void> loginWithGoogle() async {
    final rateLimit = _ref.read(rateLimitProvider.notifier);
    try {
      await AuthService.instance.signInWithGoogle();
      rateLimit.reset(); 
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ── Register ────────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String classGroup,
    required String section,
    required String rollNo,
    required String grNumber,
  }) async {
    // Client-side domain check
    final domainError = AppValidators.emailDomain(email);
    if (domainError != null) throw Exception(domainError);

    // Sanitize all text fields before writing to Firestore
    final profile = UserModel(
      uid:        '', // Filled in by AuthService after createUser
      name:       InputSanitizer.sanitizeTitle(name),
      email:      email.trim().toLowerCase(),
      phone:      InputSanitizer.sanitizeText(phone),
      classGroup: InputSanitizer.sanitizeText(classGroup),
      section:    InputSanitizer.sanitizeText(section),
      rollNo:     InputSanitizer.sanitizeText(rollNo),
      grNumber:   InputSanitizer.sanitizeText(grNumber),
      photoUrl:   '',
      bio:        '',
      gender:     'Other',
      role:       'student',
      createdAt:  DateTime.now(),
    );

    try {
      await AuthService.instance.register(
        email:    email.trim(),
        password: password,
        profile:  profile,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Forgot Password ─────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    final domainError = AppValidators.emailDomain(email);
    if (domainError != null) throw Exception(domainError);

    try {
      await AuthService.instance.sendPasswordResetEmail(email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await AuthService.instance.signOut();
  }

  // ── Error mapping ────────────────────────────────────────────
  String _mapFirebaseError(FirebaseAuthException e) {
    debugPrint('[Auth] FirebaseAuthException: ${e.code} — ${e.message}');
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact admin.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait before trying again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);
