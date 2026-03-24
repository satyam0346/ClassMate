import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/tasks/screens/task_list_screen.dart';
import '../features/tasks/screens/add_edit_task_screen.dart';
import '../features/timetable/screens/timetable_screen.dart';
import '../features/exams/screens/exam_list_screen.dart';
import '../features/exams/screens/add_edit_exam_screen.dart';
import '../features/announcements/screens/announcement_list_screen.dart';
import '../features/announcements/screens/announcement_detail_screen.dart';
import '../features/announcements/screens/add_announcement_screen.dart';
import '../features/materials/screens/material_list_screen.dart';
import '../features/materials/screens/add_material_screen.dart';
import '../features/admin/screens/admin_panel_screen.dart';
import '../features/admin/screens/view_all_profiles_screen.dart';
import '../shared/models/announcement_model.dart';
import '../shared/models/task_model.dart';
import '../shared/widgets/app_shell.dart';

/// Auth change notifier — triggers go_router refresh on auth state change.
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  _AuthChangeNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// App router provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation:     '/splash',
    debugLogDiagnostics: true,
    refreshListenable:   authNotifier,

    // ── Auth redirect guard ──────────────────────────────────
    redirect: (context, state) {
      final user      = FirebaseAuth.instance.currentUser;
      final isAuthed  = user != null;
      final location  = state.matchedLocation;

      final isAuthRoute = location == '/login'           ||
                          location == '/register'        ||
                          location == '/forgot-password' ||
                          location == '/splash';

      if (!isAuthed && !isAuthRoute) return '/login';
      if (isAuthed && isAuthRoute && location != '/splash') {
        return '/home/dashboard';
      }
      return null;
    },

    routes: [
      // ── Splash ──────────────────────────────────────────────
      GoRoute(
        path:    '/splash',
        name:    'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth routes ──────────────────────────────────────────
      GoRoute(
        path:    '/login',
        name:    'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key:   state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path:    '/register',
        name:    'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key:   state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
        ),
      ),
      GoRoute(
        path:    '/forgot-password',
        name:    'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key:   state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1), end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
        ),
      ),

      // ── App shell (bottom nav) ───────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(
          child:    child,
          location: state.matchedLocation,
        ),
        routes: [

          // ── Home / Dashboard ───────────────────────────────────
          GoRoute(
            path:    '/home/dashboard',
            name:    'dashboard',
            builder: (_, __) => const HomeScreen(),
          ),

          // ── Tasks ──────────────────────────────────────────────
          GoRoute(
            path:    '/home/tasks',
            name:    'tasks',
            builder: (_, __) => const TaskListScreen(),
            routes: [
              GoRoute(
                path:    'add',
                name:    'add-task',
                // Push outside shell so Bottom Nav hides
                pageBuilder: (context, state) => CustomTransitionPage(
                  key:   state.pageKey,
                  child: const AddEditTaskScreen(),
                  transitionsBuilder: _slideUp,
                ),
              ),
              GoRoute(
                path:    ':id',
                name:    'task-detail',
                pageBuilder: (context, state) {
                  final task = state.extra as TaskModel?;
                  return CustomTransitionPage(
                    key:   state.pageKey,
                    child: AddEditTaskScreen(existing: task),
                    transitionsBuilder: _slideUp,
                  );
                },
              ),
            ],
          ),

          // ── Timetable ──────────────────────────────────────────
          GoRoute(
            path:    '/home/timetable',
            name:    'timetable',
            builder: (_, __) => const TimetableScreen(),
          ),


          // ── Materials ──────────────────────────────────────────
          GoRoute(
            path:    '/home/materials',
            name:    'materials',
            builder: (_, __) => const MaterialListScreen(),
            routes: [
              GoRoute(
                path:    'add',
                name:    'add-material',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key:   state.pageKey,
                  child: const AddMaterialScreen(),
                  transitionsBuilder: _slideUp,
                ),
              ),
            ],
          ),


          // ── Exams ──────────────────────────────────────────────
          GoRoute(
            path:    '/home/exams',
            name:    'exams',
            builder: (_, __) => const ExamListScreen(),
            routes: [
              GoRoute(
                path:    'add',
                name:    'add-exam',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key:   state.pageKey,
                  child: const AddEditExamScreen(),
                  transitionsBuilder: _slideUp,
                ),
              ),
              GoRoute(
                path:    'edit/:id',
                name:    'edit-exam',
                pageBuilder: (context, state) {
                  final exam = state.extra;
                  return CustomTransitionPage(
                    key:   state.pageKey,
                    child: AddEditExamScreen(existing: exam as dynamic),
                    transitionsBuilder: _slideUp,
                  );
                },
              ),
            ],
          ),

          // ── Announcements ──────────────────────────────────────
          GoRoute(
            path:    '/home/announcements',
            name:    'announcements',
            builder: (_, __) => const AnnouncementListScreen(),
            routes: [
              GoRoute(
                path:    'add',
                name:    'add-announcement',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key:   state.pageKey,
                  child: const AddAnnouncementScreen(),
                  transitionsBuilder: _slideUp,
                ),
              ),
              GoRoute(
                path:    'edit/:id',
                name:    'edit-announcement',
                pageBuilder: (context, state) {
                  final a = state.extra as AnnouncementModel?;
                  return CustomTransitionPage(
                    key:   state.pageKey,
                    child: AddAnnouncementScreen(existing: a),
                    transitionsBuilder: _slideUp,
                  );
                },
              ),
              GoRoute(
                path:    ':id',
                name:    'announcement-detail',
                builder: (context, state) {
                  final a = state.extra as AnnouncementModel?;
                  if (a == null) return const _PlaceholderScreen('Not found');
                  return AnnouncementDetailScreen(announcement: a);
                },
              ),
            ],
          ),

          // ── Profile ────────────────────────────────────────────
          GoRoute(
            path:    '/home/profile',
            name:    'profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path:    'edit',
                name:    'edit-profile',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key:   state.pageKey,
                  child: const EditProfileScreen(),
                  transitionsBuilder: _slideUp,
                ),
              ),
            ],
          ),

          // ── Admin Panel ────────────────────────────────────────
          GoRoute(
            path:    '/home/admin',
            name:    'admin',
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return '/login';
              return null; // Firestore rules enforce admin-only data access
            },
            builder: (_, __) => const AdminPanelScreen(),
            routes: [
              GoRoute(
                path: 'students',
                name: 'admin-students',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ViewAllProfilesScreen(),
                  transitionsBuilder: _slideUp,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ── Shared transitions ────────────────────────────────────────

Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
    get _slideUp => (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end:   Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );

// ── Placeholder (removed once each feature is built) ─────────

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_rounded,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Coming in next phase',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey)),
            ],
          ),
        ),
      );
}
