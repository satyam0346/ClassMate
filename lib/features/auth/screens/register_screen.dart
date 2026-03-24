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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _classCtrl    = TextEditingController();
  final _sectionCtrl  = TextEditingController();
  final _rollCtrl     = TextEditingController();
  final _grCtrl       = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool  _isLoading    = false;
  // Domain error shown in real-time as user types
  String? _domainError;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _emailCtrl.addListener(_onEmailChanged);
  }

  /// Validates domain on every keystroke — instant client-side feedback.
  void _onEmailChanged() {
    final err = AppValidators.emailDomain(_emailCtrl.text);
    if (err != _domainError) setState(() => _domainError = err);
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _emailCtrl.removeListener(_onEmailChanged);
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl, _classCtrl,
      _sectionCtrl, _rollCtrl, _grCtrl, _passCtrl, _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).register(
        email:      _emailCtrl.text,
        password:   _passCtrl.text,
        name:       _nameCtrl.text,
        phone:      _phoneCtrl.text,
        classGroup: _classCtrl.text,
        section:    _sectionCtrl.text,
        rollNo:     _rollCtrl.text,
        grNumber:   _grCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created! Awaiting admin approval.'),
          backgroundColor: AppColors.success,
        ));
      }
      // Router redirect handles navigation
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).loginWithGoogle();
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
          // Background gradient
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
                // Compact header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical:   AppSizes.lg,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Join your class on ClassMate',
                            style: TextStyle(
                              color:    Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.05),

                // Form card
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
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppSizes.lg,
                          AppSizes.xl,
                          AppSizes.lg,
                          MediaQuery.of(context).viewInsets.bottom + AppSizes.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Personal info ───────────────
                            _SectionLabel('Personal Information'),
                            const SizedBox(height: AppSizes.md),
                            AuthTextField(
                              label:      AppStrings.fullName,
                              hint:       'Enter your full name',
                              controller: _nameCtrl,
                              prefixIcon: const Icon(Icons.person_outline),
                              maxLength:  100,
                              validator: (v) =>
                                  AppValidators.required(v, fieldName: 'Full name'),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Email with domain error
                            AuthTextField(
                              label:        AppStrings.email,
                              hint:         'you@marwadiuniversity.ac.in',
                              controller:   _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon:   const Icon(Icons.email_outlined),
                              validator:    AppValidators.registerEmail,
                              suffixIcon: _domainError == null &&
                                      _emailCtrl.text.isNotEmpty
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.success)
                                  : null,
                            ),
                            // Real-time domain error hint
                            if (_domainError != null && _emailCtrl.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: AppSizes.xs, left: AppSizes.md),
                                child: Text(
                                  '⚠️ ${AppStrings.errorDomainBlocked}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSizes.md),

                            AuthTextField(
                              label:        AppStrings.phone,
                              hint:         '10-digit mobile number',
                              controller:   _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              prefixIcon:   const Icon(Icons.phone_outlined),
                              maxLength:    15,
                              validator:    AppValidators.phone,
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // ── Academic info ────────────────
                            _SectionLabel('Academic Details'),
                            const SizedBox(height: AppSizes.md),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AuthTextField(
                                    label:      AppStrings.classLabel,
                                    hint:       'e.g. B.Tech IT',
                                    controller: _classCtrl,
                                    prefixIcon: const Icon(Icons.class_outlined),
                                    maxLength:  50,
                                    validator:  (v) => AppValidators.required(
                                        v, fieldName: 'Class'),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: AuthTextField(
                                    label:      AppStrings.section,
                                    hint:       'e.g. A',
                                    controller: _sectionCtrl,
                                    maxLength:  10,
                                    validator:  (v) => AppValidators.required(
                                        v, fieldName: 'Section'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.md),
                            Row(
                              children: [
                                Expanded(
                                  child: AuthTextField(
                                    label:      AppStrings.rollNo,
                                    hint:       'e.g. 42',
                                    controller: _rollCtrl,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: const Icon(Icons.tag),
                                    maxLength:  20,
                                    validator:  (v) => AppValidators.required(
                                        v, fieldName: 'Roll No'),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: AuthTextField(
                                    label:      AppStrings.grNumber,
                                    hint:       'GR Number',
                                    controller: _grCtrl,
                                    maxLength:  20,
                                    validator:  (v) => AppValidators.required(
                                        v, fieldName: 'GR Number'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // ── Password ─────────────────────
                            _SectionLabel('Security'),
                            const SizedBox(height: AppSizes.md),
                            AuthTextField(
                              label:       'Password',
                              hint:        'Minimum 8 characters',
                              controller:  _passCtrl,
                              obscureText: true,
                              prefixIcon:  const Icon(Icons.lock_outline),
                              validator:   AppValidators.password,
                            ),
                            const SizedBox(height: AppSizes.md),
                            AuthTextField(
                              label:       'Confirm Password',
                              controller:  _confirmCtrl,
                              obscureText: true,
                              prefixIcon:  const Icon(Icons.lock_outline),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) => AppValidators.confirmPassword(
                                  v, _passCtrl.text),
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Register button
                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : const Text('Create Account',
                                        style: TextStyle(fontSize: 16)),
                              ),
                            ),
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
                                      'Sign Up with Google',
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

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.accent
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.accent,
            letterSpacing: 0.5,
          ),
    );
  }
}
