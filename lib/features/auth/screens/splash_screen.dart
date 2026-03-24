import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/security/root_detection.dart';
import '../../../core/security/dio_interceptor.dart';
import '../../../shared/widgets/ota_update_dialog.dart';

/// Splash screen — first screen shown on app launch.
///
/// Checks (in order):
///   1. Maintenance mode
///   2. Force update
///   3. Auth state → navigate to dashboard or login
///   4. Root / emulator warning (show dialog, don't block)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Run checks after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartupChecks());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _runStartupChecks() async {
    // Small delay to let the splash animation be visible
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final rc = RemoteConfigService.instance;

    // 1. Maintenance mode
    if (rc.maintenanceMode) {
      _showMaintenanceDialog();
      return;
    }

    // 2. Force update check
    final needsUpdate = await rc.isUpdateRequired();
    if (!mounted) return;
    if (needsUpdate) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => OtaUpdateDialog(
          message:    rc.updateMessage,
          downloadUrl: rc.apkDownloadUrl,
        ),
      );
      // User must update — don't proceed
      return;
    }

    // 3. Root detection warning (non-blocking)
    final isRooted = await RootDetection.isRooted();
    if (!mounted) return;
    if (isRooted) {
      await _showSecurityWarning(
        'Rooted Device Detected',
        'This device appears to be rooted. Some security features '
        'may not function correctly. Proceed with caution.',
      );
    }

    // 4. Emulator detection warning (non-blocking)
    if (!mounted) return;
    final isEmulator = await EmulatorDetection.isEmulator();
    if (!mounted) return;
    if (isEmulator) {
      await _showSecurityWarning(
        'Emulator Detected',
        'ClassMate is running on an emulator. This is not '
        'recommended for regular use.',
      );
    }

    // 5. Navigate based on auth state
    if (!mounted) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      context.go('/home/dashboard');
    } else {
      context.go('/login');
    }
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          icon: const Icon(Icons.construction_rounded,
              color: AppColors.warning, size: 48),
          title: const Text('Under Maintenance'),
          content: const Text(
            'ClassMate is currently under maintenance.\n'
            'Please check back soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _showSecurityWarning(String title, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.security_rounded,
            color: AppColors.warning, size: 40),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [Color(0xFF0D0D3D), Color(0xFF1A1A5E), Color(0xFF1E1E7A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Transform.scale(
                  scale: 1.0 + (_pulseCtrl.value * 0.04),
                  child: child,
                ),
                child: Container(
                  width:  96,
                  height: 96,
                  decoration: BoxDecoration(
                    color:        AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color:      AppColors.accent.withOpacity(0.3),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.accent,
                    size:  48,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),
              const SizedBox(height: AppSizes.lg),
              const Text(
                'ClassMate',
                style: TextStyle(
                  color:      Colors.white,
                  fontSize:   36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Your academic companion',
                style: TextStyle(
                  color:    Colors.white.withOpacity(0.55),
                  fontSize: 15,
                ),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: AppSizes.xxl),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:       AppColors.accent.withOpacity(0.7),
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
