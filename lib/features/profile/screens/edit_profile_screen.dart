import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../features/auth/widgets/auth_text_field.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _classCtrl    = TextEditingController();
  final _sectionCtrl  = TextEditingController();
  final _rollCtrl     = TextEditingController();
  final _grCtrl       = TextEditingController();
  final _bioCtrl      = TextEditingController();
  String _selectedGender = 'Other';
  bool  _initialized  = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _classCtrl,
      _sectionCtrl, _rollCtrl, _grCtrl, _bioCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFields(dynamic user) {
    if (_initialized || user == null) return;
    _initialized      = true;
    _nameCtrl.text    = user.name;
    _phoneCtrl.text   = user.phone;
    _classCtrl.text   = user.classGroup;
    _sectionCtrl.text = user.section;
    _rollCtrl.text    = user.rollNo;
    _grCtrl.text      = user.grNumber;
    _bioCtrl.text     = user.bio;
    _selectedGender   = user.gender;
  }

  Future<void> _submit(String uid) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(profileControllerProvider.notifier).updateProfile(
      uid:        uid,
      name:       _nameCtrl.text,
      phone:      _phoneCtrl.text,
      classGroup: _classCtrl.text,
      section:    _sectionCtrl.text,
      rollNo:     _rollCtrl.text,
      grNumber:   _grCtrl.text,
      bio:        _bioCtrl.text,
      gender:     _selectedGender,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid       = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final userAsync = ref.watch(userModelProvider);
    final editState = ref.watch(profileControllerProvider);
    final isDark    = context.isDark;

    // Pre-fill fields once user loads
    userAsync.whenData(_initFields);

    // Show outcome
    ref.listen(profileControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(profileControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess('Profile updated!');
        ref.read(profileControllerProvider.notifier).resetState();
        context.pop();
      }
    });

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
                      Expanded(
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.05),

                // Avatar with edit overlay
                const ProfileAvatar(
                  size:     AppSizes.avatarMd,
                  editable: true,
                ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),

                if (editState.isSaving && editState.uploadProgress < 1)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.sm),
                    child: Text(
                      'Uploading photo… ${(editState.uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: AppSizes.lg),

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
                          color:      Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset:     const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppSizes.lg, AppSizes.xl, AppSizes.lg,
                          MediaQuery.of(context).viewInsets.bottom + AppSizes.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Personal'),
                            const SizedBox(height: AppSizes.md),
                            AuthTextField(
                              label:      'Full Name',
                              controller: _nameCtrl,
                              prefixIcon: const Icon(Icons.person_outline),
                              maxLength:  100,
                              validator:  (v) =>
                                  AppValidators.required(v, fieldName: 'Name'),
                            ),
                            const SizedBox(height: AppSizes.md),
                            // Gender Selection
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(Icons.people_outline_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                ),
                              ),
                              items: ['Male', 'Female', 'Other']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedGender = v!),
                            ),
                            const SizedBox(height: AppSizes.md),
                            AuthTextField(
                              label:      'Bio / About Me',
                              controller: _bioCtrl,
                              prefixIcon: const Icon(Icons.info_outline_rounded),
                              maxLength:  250,
                              maxLines:    3,
                            ),
                            const SizedBox(height: AppSizes.md),
                            AuthTextField(
                              label:        'Phone Number',
                              controller:   _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              prefixIcon:   const Icon(Icons.phone_outlined),
                              maxLength:    15,
                              validator:    AppValidators.phone,
                            ),
                            const SizedBox(height: AppSizes.xl),
                            _SectionLabel('Academic'),
                            const SizedBox(height: AppSizes.md),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AuthTextField(
                                    label:      'Class',
                                    controller: _classCtrl,
                                    maxLength:  50,
                                    validator: (v) =>
                                        AppValidators.required(
                                            v, fieldName: 'Class'),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: AuthTextField(
                                    label:      'Section',
                                    controller: _sectionCtrl,
                                    maxLength:  10,
                                    validator: (v) =>
                                        AppValidators.required(
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
                                    label:        'Roll No',
                                    controller:   _rollCtrl,
                                    keyboardType: TextInputType.number,
                                    maxLength:    20,
                                    validator: (v) =>
                                        AppValidators.required(
                                            v, fieldName: 'Roll No'),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: AuthTextField(
                                    label:      'GR Number',
                                    controller: _grCtrl,
                                    maxLength:  20,
                                    validator: (v) =>
                                        AppValidators.required(
                                            v, fieldName: 'GR Number'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.xl),
                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: editState.isSaving
                                    ? null
                                    : () => _submit(uid),
                                child: editState.isSaving
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Changes'),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color:         AppColors.accent,
              letterSpacing: 0.8,
            ),
      );
}
