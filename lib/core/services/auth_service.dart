import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../shared/models/user_model.dart';
import '../constants/app_strings.dart';
import 'notification_service.dart';
import 'remote_config_service.dart';

/// Firebase Authentication + Firestore user profile service.
/// All methods are pure async — no state management here.
/// State is handled by AuthController + Riverpod providers.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ── Current user ──────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign In ───────────────────────────────────────────────
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email:    email.trim().toLowerCase(),
      password: password,
    );
  }

  // ── Sign In with Google ───────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? (dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID') ?? '') : null,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled.');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Ensure Firestore document exists
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // Create initial profile from Google info.
      // Academic fields are empty strings due to relaxed rules.
      await _firestore.collection('users').doc(user.uid).set({
        'name':       user.displayName ?? 'New User',
        'email':      user.email ?? '',
        'phone':      user.phoneNumber ?? '',
        'classGroup': '',
        'section':    '',
        'rollNo':     '',
        'grNumber':   '',
        'photoUrl':   user.photoURL ?? '',
        'bio':        '',
        'gender':     'Other',
        'role':       'student',
        'createdAt':  FieldValue.serverTimestamp(),
      });
    }
    return userCredential;
  }

  // ── Register ──────────────────────────────────────────────
  /// Creates Firebase Auth user + writes Firestore user document.
  Future<void> register({
    required String    email,
    required String    password,
    required UserModel profile,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email.trim().toLowerCase(),
      password: password,
    );

    final uid = credential.user!.uid;

    // Write user document. Role is always "student" on registration.
    // Admin sets role: "admin" manually in Firebase Console.
    await _firestore.collection('users').doc(uid).set({
      ...profile.toFirestore(),
      'role': 'student', // Enforced here AND in Firestore rules
    });

    // Subscribe to FCM topics immediately after registration.
    try {
      await NotificationService.instance.subscribeToTopics();
      debugPrint('[Auth] Subscribed to FCM topics');
    } catch (e) {
      // FCM subscription failure is non-fatal
      debugPrint('[Auth] FCM subscription failed (non-fatal): $e');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await NotificationService.instance.unsubscribeFromTopics();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Password Reset ────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  // ── Token ─────────────────────────────────────────────────
  /// Get the current user's Firebase ID token.
  /// Used for FCM HTTP v1 API calls in NotificationService.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  // ── Firestore User Profile ────────────────────────────────
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream the current user's Firestore document.
  /// Used by userModelProvider to react to profile changes in real-time.
  Stream<UserModel?> userModelStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ── Token revocation guard ────────────────────────────────
  /// Listen for token revocation. If the token is revoked server-side,
  /// force sign-out so the user must re-authenticate.
  void listenForTokenRevocation() {
    _auth.idTokenChanges().listen((user) async {
      if (user == null) return;
      try {
        // Force-refresh the token to detect server-side revocation.
        await user.getIdToken(true);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-token-expired' ||
            e.code == 'user-disabled'      ||
            e.code == 'token-expired') {
          debugPrint('[Auth] Token revoked — forcing sign out: ${e.code}');
          await signOut();
        }
      }
    });
  }
}

// ── Riverpod Providers ────────────────────────────────────────

/// Watches Firebase auth state. Null = unauthenticated.
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// Watches the signed-in user's Firestore profile document.
/// Returns null if user is not authenticated or has no profile.
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return AuthService.instance.userModelStream(user.uid);
});

/// Convenience provider — true if the current user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  final userModel = ref.watch(userModelProvider).valueOrNull;

  // 1. Database check (user.role == 'admin')
  if (userModel?.isAdmin ?? false) return true;

  // 2. Secret Remote Config check (keeps email out of source code)
  final superAdmins = RemoteConfigService.instance.superAdmins
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  if (userModel != null && superAdmins.contains(userModel.email.toLowerCase())) {
    return true;
  }

  return false;
});
