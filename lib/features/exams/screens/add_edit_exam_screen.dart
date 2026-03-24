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
import '../../../shared/models/exam_model.dart';
import '../controllers/exam_controller.dart';

class AddEditExamScreen extends ConsumerStatefulWidget {
  final ExamModel? existing;
  const AddEditExamScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends ConsumerState<AddEditExamScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _subjectCtrl  = TextEditingController();
  final _venueCtrl    = TextEditingController();
  final _notesCtrl    = TextEditingController();

  DateTime _examDate    = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _examTime   = const TimeOfDay(hour: 10, minute: 0);
  String    _type       = 'theory';
  int       _durationMins = 60;
  bool      _isOfficial  = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e         = widget.existing!;
      _subjectCtrl.text = e.subject;
      _venueCtrl.text   = e.venue;
      _notesCtrl.text   = e.notes;
      _examDate     = e.examDate;
      _examTime     = TimeOfDay(hour: e.examDate.hour,
                                minute: e.examDate.minute);
      _type         = e.type;
      _durationMins = e.durationMins;
      _isOfficial   = e.isOfficial;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _venueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime _combinedDateTime() => DateTime(
    _examDate.year,
    _examDate.month,
    _examDate.day,
    _examTime.hour,
    _examTime.minute,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:        context,
      initialDate:    _examDate,
      firstDate:      DateTime.now(),
      lastDate:       DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context:     context,
      initialTime: _examTime,
    );
    if (picked != null) setState(() => _examTime = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid   = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final ctrl  = ref.read(examControllerProvider.notifier);
    final dt    = _combinedDateTime();

    if (dt.isBefore(DateTime.now())) {
      context.showError('Exam date & time must be in the future.');
      return;
    }

    if (_isEdit) {
      await ctrl.updateExam(widget.existing!.copyWith(
        subject:      _subjectCtrl.text,
        examDate:     dt,
        venue:        _venueCtrl.text,
        notes:        _notesCtrl.text,
        type:         _type,
        durationMins: _durationMins,
        isOfficial:   _isOfficial,
      ));
    } else {
      await ctrl.createExam(
        subject:      _subjectCtrl.text,
        examDate:     dt,
        venue:        _venueCtrl.text,
        notes:        _notesCtrl.text,
        type:         _type,
        durationMins: _durationMins,
        isOfficial:   _isOfficial,
        createdBy:    uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = context.isDark;
    final crudState  = ref.watch(examControllerProvider);

    ref.listen(examControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(examControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess(_isEdit ? 'Exam updated!' : 'Exam added!');
        ref.read(examControllerProvider.notifier).resetState();
        context.pop();
      }
    });

    // Duration options: 30m, 1h, 1.5h, 3h
    final durations = [30, 60, 90, 180];

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
                          _isEdit ? 'Edit Exam' : 'Add Exam',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.05),

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

                            // Subject
                            AuthTextField(
                              label:      'Subject *',
                              hint:       'e.g. Data Structures',
                              controller: _subjectCtrl,
                              prefixIcon: const Icon(Icons.menu_book_outlined),
                              maxLength:  200,
                              validator: (v) =>
                                  AppValidators.required(v, fieldName: 'Subject'),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Venue
                            AuthTextField(
                              label:      'Venue / Hall',
                              hint:       'e.g. Exam Hall A',
                              controller: _venueCtrl,
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              maxLength:  100,
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Date & Time row
                            _SectionLabel('Date & Time'),
                            const SizedBox(height: AppSizes.sm),
                            Row(
                              children: [
                                Expanded(child: _PickerButton(
                                  icon:   Icons.calendar_today_outlined,
                                  label:  'Date',
                                  value:  _examDate.formattedDate,
                                  onTap:  _pickDate,
                                  isDark: isDark,
                                )),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(child: _PickerButton(
                                  icon:   Icons.access_time_outlined,
                                  label:  'Time',
                                  value:  _examTime.format(context),
                                  onTap:  _pickTime,
                                  isDark: isDark,
                                )),
                              ],
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Exam type
                            _SectionLabel('Exam Type'),
                            const SizedBox(height: AppSizes.sm),
                            Wrap(
                              spacing: AppSizes.sm,
                              children: ['theory', 'practical', 'quiz', 'viva']
                                  .map((t) => ChoiceChip(
                                        label:    Text(_typeLabel(t)),
                                        selected: _type == t,
                                        onSelected: (_) =>
                                            setState(() => _type = t),
                                        selectedColor: AppColors.primary,
                                        labelStyle: TextStyle(
                                          color:      _type == t
                                              ? Colors.white
                                              : null,
                                          fontWeight: _type == t
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Duration
                            _SectionLabel('Duration'),
                            const SizedBox(height: AppSizes.sm),
                            Wrap(
                              spacing: AppSizes.sm,
                              children: durations
                                  .map((d) => ChoiceChip(
                                        label:    Text(d < 60
                                            ? '${d}m'
                                            : '${d ~/ 60}h${d % 60 == 0 ? '' : ' ${d % 60}m'}'),
                                        selected: _durationMins == d,
                                        onSelected: (_) =>
                                            setState(() => _durationMins = d),
                                        selectedColor: AppColors.primary,
                                        labelStyle: TextStyle(
                                          color:      _durationMins == d
                                              ? Colors.white
                                              : null,
                                          fontWeight: _durationMins == d
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: AppSizes.xl),

                            // Official toggle
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
                                  const Icon(Icons.verified_outlined,
                                      color: AppColors.accent),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Official Exam',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        Text(
                                          'Marks this as an officially scheduled exam',
                                          style: context.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value:     _isOfficial,
                                    onChanged: (v) =>
                                        setState(() => _isOfficial = v),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Notes
                            AuthTextField(
                              label:      'Notes / Instructions',
                              hint:       'Syllabus, special instructions...',
                              controller: _notesCtrl,
                              prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                              maxLength:  1000,
                            ),
                            const SizedBox(height: AppSizes.xl),

                            SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    crudState.isSaving ? null : _submit,
                                child: crudState.isSaving
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color:       Colors.white,
                                        ),
                                      )
                                    : Text(_isEdit
                                        ? 'Update Exam'
                                        : 'Add Exam'),
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

  String _typeLabel(String t) => switch (t) {
    'practical' => '🔬 Practical',
    'quiz'      => '📝 Quiz',
    'viva'      => '🎤 Viva',
    _           => '📚 Theory',
  };
}

// ── Helpers ───────────────────────────────────────────────────

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

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final VoidCallback onTap;
  final bool     isDark;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            prefixIcon:  Icon(icon),
            filled:      true,
            fillColor:   isDark ? AppColors.cardDark : AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.md),
          ),
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}
