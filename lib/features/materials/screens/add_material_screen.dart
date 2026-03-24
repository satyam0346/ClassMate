import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
import '../controllers/material_controller.dart';
import '../widgets/material_card.dart';

class AddMaterialScreen extends ConsumerStatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  ConsumerState<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends ConsumerState<AddMaterialScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _urlCtrl     = TextEditingController();

  File?   _pickedFile;
  String? _pickedFileName;
  int     _fileSizeBytes = 0;
  bool    _isLinkMode    = false; // toggle: file upload vs URL link

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type:             FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'ppt', 'pptx',
          'xls', 'xlsx', 'txt', 'csv', 'odt',
          'jpg', 'jpeg', 'png', 'gif', 'webp',
          'mp4', 'zip',
        ],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final pf = result.files.first;
      if (pf.path == null) return;

      setState(() {
        _pickedFile     = File(pf.path!);
        _pickedFileName = pf.name;
        _fileSizeBytes  = pf.size;
      });
    } catch (e) {
      if (mounted) context.showError('Could not open file picker: $e');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid  = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final ctrl = ref.read(materialControllerProvider.notifier);

    if (_isLinkMode) {
      await ctrl.addLink(
        title:       _titleCtrl.text,
        url:         _urlCtrl.text.trim(),
        subject:     _subjectCtrl.text,
        description: _descCtrl.text,
        uploadedBy:  uid,
      );
    } else {
      if (_pickedFile == null) {
        context.showError('Please select a file to upload.');
        return;
      }
      await ctrl.uploadFile(
        file:        _pickedFile!,
        title:       _titleCtrl.text,
        subject:     _subjectCtrl.text,
        description: _descCtrl.text,
        uploadedBy:  uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = context.isDark;
    final uploadState = ref.watch(materialControllerProvider);

    ref.listen(materialControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(materialControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess('Material uploaded!');
        ref.read(materialControllerProvider.notifier).resetState();
        context.pop();
      }
    });

    final isUploading = uploadState.isUploading;
    final progress    = uploadState.uploadProgress;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [Color(0xFF0D0D3D), Color(0xFF1A1A5E),
                         Color(0xFF1a3a5e)],
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
                      const Expanded(
                        child: Text(
                          'Upload Material',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.05),

                // Form
                Expanded(
                  child: Container(
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

                            // File / Link toggle
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardDark
                                    : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusRound),
                              ),
                              child: Row(
                                children: [
                                  _ModeTab(
                                    label:    '📁 Upload File',
                                    selected: !_isLinkMode,
                                    onTap:    () =>
                                        setState(() => _isLinkMode = false),
                                  ),
                                  _ModeTab(
                                    label:    '🔗 Add Link',
                                    selected: _isLinkMode,
                                    onTap:    () =>
                                        setState(() => _isLinkMode = true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Title field
                            AuthTextField(
                              label:      'Title *',
                              hint:       'e.g. DBMS Lecture Notes Unit 3',
                              controller: _titleCtrl,
                              maxLength:  200,
                              prefixIcon: const Icon(Icons.title_rounded),
                              validator: (v) =>
                                  AppValidators.required(v, fieldName: 'Title'),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Subject field
                            AuthTextField(
                              label:      'Subject *',
                              hint:       'e.g. Database Management Systems',
                              controller: _subjectCtrl,
                              maxLength:  100,
                              prefixIcon: const Icon(Icons.book_outlined),
                              validator: (v) => AppValidators.required(v,
                                  fieldName: 'Subject'),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Description
                            AuthTextField(
                              label:      'Description (optional)',
                              hint:       'Brief description of this material',
                              controller: _descCtrl,
                              maxLength:  500,
                              prefixIcon: const Icon(Icons.short_text_rounded),
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // File picker or URL field
                            if (!_isLinkMode) ...[
                              _SectionLabel('File'),
                              const SizedBox(height: AppSizes.sm),
                              GestureDetector(
                                onTap: isUploading ? null : _pickFile,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width:   double.infinity,
                                  padding: const EdgeInsets.all(AppSizes.lg),
                                  decoration: BoxDecoration(
                                    color: _pickedFile != null
                                        ? AppColors.primary.withOpacity(0.05)
                                        : (isDark
                                            ? AppColors.cardDark
                                            : AppColors.cardLight),
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusLg),
                                    border: Border.all(
                                      color: _pickedFile != null
                                          ? AppColors.primary.withOpacity(0.5)
                                          : (isDark
                                              ? AppColors.dividerDark
                                              : AppColors.dividerLight),
                                      style: _pickedFile == null
                                          ? BorderStyle.solid
                                          : BorderStyle.solid,
                                      width: _pickedFile != null ? 1.5 : 1,
                                    ),
                                  ),
                                  child: _pickedFile == null
                                      ? const Column(
                                          children: [
                                            Icon(Icons.upload_file_rounded,
                                                size: 40,
                                                color: AppColors.primary),
                                            SizedBox(height: AppSizes.sm),
                                            Text('Tap to choose a file',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                )),
                                            SizedBox(height: 4),
                                            Text(
                                              'PDF, DOC, PPT, XLS, images, ZIP • Max 50MB',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondaryLight,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              materialTypeIcon(
                                                _pickedFileName
                                                        ?.split('.')
                                                        .last
                                                        .toLowerCase() ??
                                                    'other'),
                                              color: AppColors.primary,
                                              size: 32,
                                            ),
                                            const SizedBox(width: AppSizes.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _pickedFileName ?? '',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    _fileSizeBytes < 1048576
                                                        ? '${(_fileSizeBytes / 1024).toStringAsFixed(1)} KB'
                                                        : '${(_fileSizeBytes / 1048576).toStringAsFixed(1)} MB',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondaryLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => setState(() {
                                                _pickedFile     = null;
                                                _pickedFileName = null;
                                                _fileSizeBytes  = 0;
                                              }),
                                              child: const Text('Change'),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ] else ...[
                              AuthTextField(
                                label:       'URL *',
                                hint:        'https://drive.google.com/...',
                                controller:  _urlCtrl,
                                maxLength:   1000,
                                prefixIcon:  const Icon(Icons.link_rounded),
                                keyboardType: TextInputType.url,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'URL is required.';
                                  }
                                  final uri = Uri.tryParse(v.trim());
                                  if (uri == null || !uri.hasScheme) {
                                    return 'Enter a valid URL.';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: AppSizes.xl),

                            // Upload progress bar
                            if (isUploading && !_isLinkMode) ...[
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusRound),
                                child: LinearProgressIndicator(
                                  value:            progress,
                                  backgroundColor:  AppColors.dividerLight,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.primary),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading… ${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color:    AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                            ],

                            // Submit
                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: isUploading ? null : _submit,
                                icon: isUploading
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:       Colors.white))
                                    : Icon(_isLinkMode
                                        ? Icons.add_link_rounded
                                        : Icons.upload_rounded),
                                label: Text(_isLinkMode
                                    ? 'Add Link'
                                    : 'Upload Material'),
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

// ── Mode tab ──────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration:   const Duration(milliseconds: 180),
            padding:    const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      selected ? Colors.white : AppColors.textSecondaryLight,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize:   13,
              ),
            ),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.accent, letterSpacing: 0.8),
      );
}
