import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/notification_service.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Load .env — MUST run before anything else ────────
  // App crashes here if .env is missing. This is intentional.
  // Developers must create .env from .env.example before running.
  await dotenv.load(fileName: '.env');

  // ── Step 2: Initialize Firebase from .env values ─────────────
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey:            dotenv.get('FIREBASE_API_KEY'),
      authDomain:        dotenv.get('FIREBASE_AUTH_DOMAIN'),
      projectId:         dotenv.get('FIREBASE_PROJECT_ID'),
      storageBucket:     dotenv.get('FIREBASE_STORAGE_BUCKET'),
      messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
      appId:             dotenv.get('FIREBASE_APP_ID'),
    ),
  );

  // ── Step 3: Enable Firestore offline persistence ──────────────
  // This single call enables full offline read/write caching.
  // All Firestore reads work offline using the local cache.
  // Queued writes fire automatically when connectivity restores.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled:  true,
    cacheSizeBytes:      Settings.CACHE_SIZE_UNLIMITED,
  );

  // ── Step 4: Fetch Remote Config ───────────────────────────────
  // OTA check, maintenance mode, allowed domains from server.
  // Errors are caught internally — app continues with defaults.
  await RemoteConfigService.instance.init();

  // ── Step 5: Start token revocation listener ───────────────────
  // Signs out user if their Firebase token is revoked server-side.
  AuthService.instance.listenForTokenRevocation();

  // ── Step 6: Initialize Notifications ──────────────────────────
  // Request permissions, set up FCM listeners, and local channels.
  await NotificationService.instance.init();

  // ── Step 7: Launch app ────────────────────────────────────────
  runApp(const ProviderScope(child: ClassMateApp()));
}

class ClassMateApp extends ConsumerWidget {
  const ClassMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router    = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title:                    'ClassMate',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.lightTheme,
      darkTheme:                AppTheme.darkTheme,
      themeMode:                themeMode,
      routerConfig:             router,
    );
  }
}
