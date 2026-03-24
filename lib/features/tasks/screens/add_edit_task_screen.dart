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
import '../../../shared/models/task_model.dart';
import '../controllers/task_controller.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? existing; // null = add, non-null = edit

  const AddEditTaskScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();

  String    _priority    = 'medium';
  DateTime  _dueDate     = DateTime.now().add(const Duration(days: 3));
  bool      _isClassTask = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t       = widget.existing!;
      _titleCtrl.text    = t.title;
      _descCtrl.text     = t.description;
      _subjectCtrl.text  = t.subject;
      _priority    = t.priority;
      _dueDate     = t.dueDate;
      _isClassTask = t.isClassTask;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid      = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final isAdmin  = ref.read(isAdminProvider);
    final ctrl     = ref.read(taskControllerProvider.notifier);

    if (_isEdit) {
      await ctrl.updateTask(widget.existing!.copyWith(
        title:       _titleCtrl.text,
        description: _descCtrl.text,
        subject:     _subjectCtrl.text,
        priority:    _priority,
        dueDate:     _dueDate,
      ));
    } else {
      await ctrl.createTask(
        title:       _titleCtrl.text,
        description: _descCtrl.text,
        subject:     _subjectCtrl.text,
        dueDate:     _dueDate,
        priority:    _priority,
        isClassTask: isAdmin ? _isClassTask : false,
        createdBy:   uid,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _dueDate,
      firstDate:    DateTime.now(),
      lastDate:     DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary:    AppColors.primary,
            onPrimary:  Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.isDark;
    final isAdmin  = ref.watch(isAdminProvider);
    final crudState = ref.watch(taskControllerProvider);

    // Listen for save outcome
    ref.listen(taskControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(taskControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess(_isEdit ? 'Task updated!' : 'Task added!');
        ref.read(taskControllerProvider.notifier).resetState();
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
                        child: Text(
                          _isEdit ? 'Edit Task' : 'New Task',
                          style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                          ),
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
                          MediaQuery.of(context).viewInsets.bottom + AppSizes.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            AuthTextField(
                              label:      'Task Title *',
                              hint:       'What needs to be done?',
                              controller: _titleCtrl,
                              prefixIcon: const Icon(Icons.task_alt_outlined),
                              maxLength:  200,
                              validator:  (v) =>
                                  AppValidators.required(v, fieldName: 'Title'),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Subject
                            AuthTextField(
                              label:      'Subject',
                              hint:       'e.g. Data Structures',
                              controller: _subjectCtrl,
                              prefixIcon: const Icon(Icons.book_outlined),
                              maxLength:  100,
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Description
                            AuthTextField(
                              label:      'Description',
                              hint:       'Additional details...',
                              controller: _descCtrl,
                              prefixIcon: const Icon(Icons.notes_rounded),
                              maxLength:  1000,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Due Date picker
                            _SectionLabel('Due Date'),
                            const SizedBox(height: AppSizes.sm),
                            InkWell(
                              onTap:        _pickDate,
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusSm),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? AppColors.dividerDark
                                          : AppColors.dividerLight,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                      Icons.calendar_today_outlined),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.md,
                                      vertical:   AppSizes.md),
                                  filled:    true,
                                  fillColor: isDark
                                      ? AppColors.cardDark
                                      : AppColors.surfaceLight,
                                ),
                                child: Text(
                                  _dueDate.formattedDate,
                                  style: context.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Priority
                            _SectionLabel('Priority'),
                            const SizedBox(height: AppSizes.sm),
                            Row(
                              children: [
                                _PriorityButton(
                                  label:    '🔴 High',
                                  value:    'high',
                                  selected: _priority == 'high',
                                  color:    AppColors.priorityHigh,
                                  onTap:    () => setState(() => _priority = 'high'),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                _PriorityButton(
                                  label:    '🟡 Medium',
                                  value:    'medium',
                                  selected: _priority == 'medium',
                                  color:    AppColors.priorityMedium,
                                  onTap:    () => setState(() => _priority = 'medium'),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                _PriorityButton(
                                  label:    '🟢 Low',
                                  value:    'low',
                                  selected: _priority == 'low',
                                  color:    AppColors.priorityLow,
                                  onTap:    () => setState(() => _priority = 'low'),
                                ),
                              ],
                            ),

                            // Class task toggle (admin only)
                            if (isAdmin) ...[
                              const SizedBox(height: AppSizes.lg),
                              Container(
                                padding: const EdgeInsets.all(AppSizes.md),
                                decoration: BoxDecoration(
                                  color:        isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusLg),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.dividerDark
                                        : AppColors.dividerLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.school_outlined,
                                        color: AppColors.info),
                                    const SizedBox(width: AppSizes.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Visible to entire class',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          Text(
                                            _isClassTask
                                                ? 'All students can see this task'
                                                : 'Only you can see this task',
                                            style: context.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value:    _isClassTask,
                                      onChanged: (v) =>
                                          setState(() => _isClassTask = v),
                                      activeColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSizes.xl),

                            // Save button
                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: crudState.isSaving ? null : _submit,
                                child: crudState.isSaving
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isEdit ? 'Update Task' : 'Add Task'),
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

// ── Helper widgets ────────────────────────────────────────────

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

class _PriorityButton extends StatelessWidget {
  final String   label;
  final String   value;
  final bool     selected;
  final Color    color;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: selected ? color : AppColors.dividerLight,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      selected ? color : AppColors.textSecondaryLight,
                fontSize:   12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      );
}
