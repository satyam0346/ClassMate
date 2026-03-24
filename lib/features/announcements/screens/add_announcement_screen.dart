import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/widgets/auth_text_field.dart';
import '../../../shared/models/announcement_model.dart';
import '../controllers/announcement_controller.dart';

class AddAnnouncementScreen extends ConsumerStatefulWidget {
  final AnnouncementModel? existing;
  const AddAnnouncementScreen({super.key, this.existing});

  @override
  ConsumerState<AddAnnouncementScreen> createState() =>
      _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState
    extends ConsumerState<AddAnnouncementScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _titleCtrl       = TextEditingController();
  final _messageCtrl     = TextEditingController();
  final _attachmentCtrl  = TextEditingController();

  bool _isPinned = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final a            = widget.existing!;
      _titleCtrl.text    = a.title;
      _messageCtrl.text  = a.message;
      _attachmentCtrl.text = a.attachmentUrl;
      _isPinned          = a.isPinned;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _attachmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid  = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final ctrl = ref.read(announcementControllerProvider.notifier);

    if (_isEdit) {
      await ctrl.updateAnnouncement(widget.existing!.copyWith(
        title:         _titleCtrl.text,
        message:       _messageCtrl.text,
        attachmentUrl: _attachmentCtrl.text.trim(),
        isPinned:      _isPinned,
      ));
    } else {
      await ctrl.createAnnouncement(
        title:         _titleCtrl.text,
        message:       _messageCtrl.text,
        createdBy:     uid,
        isPinned:      _isPinned,
        attachmentUrl: _attachmentCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = context.isDark;
    final crudState  = ref.watch(announcementControllerProvider);

    ref.listen(announcementControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(announcementControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess(
            _isEdit ? 'Announcement updated!' : 'Announcement posted!');
        ref.read(announcementControllerProvider.notifier).resetState();
        context.pop();
      }
    });

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
                colors: [Color(0xFF0D0D3D), Color(0xFF1A1A5E),
                         Color(0xFF1E1E7A)],
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
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit
                                  ? 'Edit Announcement'
                                  : 'New Announcement',
                              style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!_isEdit)
                              Text(
                                'Will be sent to all ${60} students via FCM',
                                style: TextStyle(
                                  color:   Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
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
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppSizes.lg, AppSizes.xl, AppSizes.lg,
                          MediaQuery.of(context).viewInsets.bottom +
                              AppSizes.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Title
                            AuthTextField(
                              label:      'Title *',
                              hint:       'e.g. Mid-sem exam schedule released',
                              controller: _titleCtrl,
                              maxLength:  200,
                              prefixIcon: const Icon(Icons.title_rounded),
                              validator: (v) =>
                                  AppValidators.required(v, fieldName: 'Title'),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Message (multiline)
                            TextFormField(
                              controller:  _messageCtrl,
                              minLines:    5,
                              maxLines:    20,
                              maxLength:   5000,
                              decoration: InputDecoration(
                                labelText:   'Message *',
                                hintText:
                                    'Write the announcement details here…',
                                alignLabelWithHint: true,
                                prefixIcon:  const Padding(
                                  padding: EdgeInsets.only(bottom: 72),
                                  child: Icon(Icons.article_outlined),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusSm),
                                ),
                                filled:    true,
                                fillColor: isDark
                                    ? AppColors.cardDark
                                    : AppColors.surfaceLight,
                              ),
                              validator: (v) => AppValidators.required(v,
                                  fieldName: 'Message'),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Attachment (optional URL)
                            AuthTextField(
                              label:      'Attachment URL (optional)',
                              hint:       'https://drive.google.com/...',
                              controller: _attachmentCtrl,
                              maxLength:  500,
                              prefixIcon: const Icon(Icons.attach_file_rounded),
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: AppSizes.lg),

                            // Pin toggle
                            Container(
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardDark
                                    : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusLg),
                                border: Border.all(
                                  color: _isPinned
                                      ? AppColors.accent.withOpacity(0.5)
                                      : (isDark
                                          ? AppColors.dividerDark
                                          : AppColors.dividerLight),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.push_pin_outlined,
                                      color: AppColors.accent),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Pin Announcement',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        Text(
                                          'Pinned announcements appear at the top',
                                          style: context.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value:     _isPinned,
                                    onChanged: (v) =>
                                        setState(() => _isPinned = v),
                                    activeColor: AppColors.accent,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // FCM info card
                            if (!_isEdit)
                              Container(
                                padding: const EdgeInsets.all(AppSizes.md),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusLg),
                                  border: Border.all(
                                    color: AppColors.info.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: AppColors.info, size: 18),
                                    const SizedBox(width: AppSizes.sm),
                                    const Expanded(
                                      child: Text(
                                        'A push notification will be sent to all '
                                        'class members subscribed to the '
                                        '"class_announcements" FCM topic.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:    AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppSizes.xl),

                            // Post button
                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed:
                                    crudState.isSaving ? null : _submit,
                                icon: crudState.isSaving
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:       Colors.white))
                                    : const Icon(Icons.send_rounded),
                                label: Text(_isEdit
                                    ? 'Update Announcement'
                                    : 'Post & Notify'),
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
