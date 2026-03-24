import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading  = false;
  bool _emailSent  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .sendPasswordReset(_emailCtrl.text);
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [Color(0xFF0D0D3D), Color(0xFF1A1A5E), Color(0xFF1E1E7A)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: AppSizes.lg),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.05),

                // Card
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
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: _emailSent
                          ? _SuccessState(email: _emailCtrl.text)
                          : Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: AppSizes.md),
                                  // Icon
                                  Container(
                                    width:  64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(AppSizes.radiusLg),
                                    ),
                                    child: const Icon(
                                      Icons.lock_reset_rounded,
                                      color: AppColors.primary,
                                      size:  32,
                                    ),
                                  ).animate().scale(
                                      curve: Curves.easeOutBack,
                                      duration: 400.ms),
                                  const SizedBox(height: AppSizes.lg),
                                  Text(
                                    'Forgot your password?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSizes.sm),
                                  Text(
                                    'Enter your university email and we\'ll send '
                                    'you a password reset link.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                  ),
                                  const SizedBox(height: AppSizes.xl),
                                  AuthTextField(
                                    label:        'University Email',
                                    hint:         'you@marwadiuniversity.ac.in',
                                    controller:   _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    prefixIcon:   const Icon(Icons.email_outlined),
                                    validator:    AppValidators.registerEmail,
                                    onSubmitted:  (_) => _submit(),
                                  ),
                                  const SizedBox(height: AppSizes.xl),
                                  SizedBox(
                                    width:  double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22, height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Send Reset Link'),
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.md),
                                  Center(
                                    child: TextButton(
                                      onPressed: () => context.pop(),
                                      child: Text(
                                        'Back to Sign In',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.accent
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
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

class _SuccessState extends StatelessWidget {
  final String email;
  const _SuccessState({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width:  88,
          height: 88,
          decoration: BoxDecoration(
            color:        AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(44),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.success,
            size:  44,
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms).fadeIn(),
        const SizedBox(height: AppSizes.lg),
        Text(
          'Check your inbox!',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          'We sent a password reset link to:\n$email',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xl),
        SizedBox(
          width:  double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }
}
