import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/security/secure_screen.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _isLoading  = false;

  @override
  void initState() {
    super.initState();
    // FLAG_SECURE — no screenshots on login screen
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .login(_emailCtrl.text, _passCtrl.text);
      // go_router redirect handles navigation after auth state changes
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).loginWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rateLimit = ref.watch(rateLimitProvider);
    final size      = MediaQuery.of(context).size;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background gradient ────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0D3D),
                  Color(0xFF1A1A5E),
                  Color(0xFF1E1E7A),
                ],
              ),
            ),
          ),

          // ── Decorative circles ───────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Logo section
                SizedBox(
                  height: size.height * 0.32,
                  child: const _LogoSection(),
                ),

                // Card section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.surfaceLight,
                      borderRadius: const BorderRadius.only(
                        topLeft:  Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset:     const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSizes.lg,
                        AppSizes.xl,
                        AppSizes.lg,
                        MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Text(
                              'Welcome back 👋',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              'Sign in to continue to ClassMate',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                            ).animate().fadeIn(delay: 150.ms),
                            const SizedBox(height: AppSizes.xl),

                            // Email field
                            AuthTextField(
                              label:          'University Email',
                              hint:           'you@marwadiuniversity.ac.in',
                              controller:     _emailCtrl,
                              keyboardType:   TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              prefixIcon:     const Icon(Icons.email_outlined),
                              validator:      AppValidators.registerEmail,
                            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),
                            const SizedBox(height: AppSizes.md),

                            // Password field
                            AuthTextField(
                              label:          'Password',
                              controller:     _passCtrl,
                              obscureText:    true,
                              textInputAction: TextInputAction.done,
                              prefixIcon:     const Icon(Icons.lock_outline),
                              validator:      AppValidators.password,
                              onSubmitted:    (_) => _submit(),
                            ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05),
                            const SizedBox(height: AppSizes.sm),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                child: Text(
                                  AppStrings.forgotPassword,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.accent
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Rate limit warning
                            if (rateLimit.isLockedOut)
                              _LockoutBanner(seconds: rateLimit.secondsRemaining)
                                  .animate()
                                  .fadeIn()
                                  .shake(),

                            const SizedBox(height: AppSizes.sm),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    (_isLoading || rateLimit.isLockedOut)
                                        ? null
                                        : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.primary.withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
                            const SizedBox(height: AppSizes.xl),

                            // ── OR Divider ───────────────────
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? AppColors.dividerDark : AppColors.dividerLight)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? AppColors.dividerDark : AppColors.dividerLight)),
                              ],
                            ).animate().fadeIn(delay: 350.ms),
                            const SizedBox(height: AppSizes.xl),

                            // ── Google Login Button ──────────
                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _loginWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 24),
                                    ),
                                    const SizedBox(width: AppSizes.md),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),
                            const SizedBox(height: AppSizes.xl),

                            // Register link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/register'),
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.accent
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 350.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo Section ──────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow effect
          Container(
            width:  80,
            height: 80,
            decoration: BoxDecoration(
              color:        AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:      AppColors.accent.withOpacity(0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.accent,
              size:  40,
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack)
              .fadeIn(),
          const SizedBox(height: AppSizes.md),
          Text(
            AppStrings.appName,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: AppSizes.xs),
          Text(
            AppStrings.appTagline,
            style: TextStyle(
              color:    Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ── Lockout Banner ────────────────────────────────────────────

class _LockoutBanner extends StatelessWidget {
  final int seconds;
  const _LockoutBanner({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      margin:  const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color:        AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border:       Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.error, size: 18),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'Too many failed attempts. Try again in ${seconds}s.',
              style: const TextStyle(
                color:    AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
