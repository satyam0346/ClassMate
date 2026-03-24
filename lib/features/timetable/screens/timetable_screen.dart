import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/timetable_controller.dart';
import '../widgets/slot_card.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/timetable_model.dart';
import '../../../shared/models/user_model.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timetableControllerProvider.notifier).syncNewTimetable();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = context.isDark;
    final isAdmin    = ref.watch(isAdminProvider);
    final timetableAsync = ref.watch(timetableStreamProvider);
    final userAsync      = ref.watch(userModelProvider); // corrected

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Giant "Classes" Header ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Classes',
                      style: context.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    userAsync.when(
                      data: (user) {
                        final url = user?.effectivePhotoUrl ?? '';
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.accent.withOpacity(0.2),
                          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                          child: url.isEmpty ? const Icon(Icons.person, color: AppColors.accent) : null,
                        );
                      },
                      loading: () => const CircleAvatar(radius: 20),
                      error:   (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.error)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Date Selector ──────────────────────────────────
            SliverToBoxAdapter(
              child: _InfiniteDateSelector(
                selectedDate:  _selectedDate,
                onDateChanged: (d) => setState(() => _selectedDate = d),
                isDark:        isDark,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.lg)),

            // ── Slot list ───────────────────────────────────────
            _SlotListSliver(
              timetableAsync: timetableAsync,
              selectedDate:  _selectedDate,
              isAdmin:       isAdmin,
              onEdit:        (day, index, slot) => _showEditSlotSheet(context, ref, day, index, slot),
              onDelete:      (day, index) => _confirmDelete(context, ref, day, index),
              onAdd:         (day) => _showAddSlotSheet(context, ref, day: day),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet helpers ──────────────────────────────────

  void _showAddSlotSheet(BuildContext context, WidgetRef ref, {String? day}) {
    final initialDay = day ?? DateFormat('EEEE').format(_selectedDate);
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditSlotSheet(day: initialDay),
    );
  }

  void _showEditSlotSheet(
      BuildContext context, WidgetRef ref, String day, int index, slot) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditSlotSheet(
        day:        day,
        slotIndex:  index,
        existing:   slot,
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String day, int index) async {
    final confirmed = await showConfirmationDialog(
      context:       context,
      title:         'Delete Slot',
      message:       'Remove this class slot from $day?',
      confirmLabel:  'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      ref.read(timetableControllerProvider.notifier).deleteSlot(day, index);
    }
  }
}

class _InfiniteDateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool isDark;

  const _InfiniteDateSelector({
    required this.selectedDate,
    required this.onDateChanged,
    required this.isDark,
  });

  @override
  State<_InfiniteDateSelector> createState() => _InfiniteDateSelectorState();
}

class _InfiniteDateSelectorState extends State<_InfiniteDateSelector> {
  late final ScrollController _scrollCtrl;
  final int _baseIndex = 10000;

  DateTime _dateForIndex(int index) {
    return DateTime.now().add(Duration(days: index - _baseIndex));
  }

  @override
  void initState() {
    super.initState();
    // approximate item width is 63, plus padding/margins
    final offset = (_baseIndex * 63.0) - 150; 
    _scrollCtrl = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM').format(widget.selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Text(
            month.toUpperCase(),
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: widget.isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            // Indefinite list
            itemBuilder: (context, index) {
              final d = _dateForIndex(index);
              final isSel = d.year == widget.selectedDate.year &&
                            d.month == widget.selectedDate.month &&
                            d.day == widget.selectedDate.day;
              
              final dayName = DateFormat('E').format(d); // e.g. "Mon"
              
              return GestureDetector(
                onTap: () => widget.onDateChanged(d),
                child: AnimatedContainer(
                  duration: 250.ms,
                  width:   55,
                  margin:  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel 
                        ? (widget.isDark ? Colors.white : AppColors.primary) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSel ? [
                      BoxShadow(
                        color: (widget.isDark ? Colors.white : AppColors.primary).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w800,
                          color: isSel 
                              ? (widget.isDark ? Colors.black : Colors.white)
                              : (widget.isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayName.toUpperCase(),
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w700,
                          color: isSel 
                              ? (widget.isDark ? Colors.black : Colors.white)
                              : (widget.isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Slot List Sliver ──────────────────────────────────────────

class _SlotListSliver extends StatelessWidget {
  final AsyncValue<Map<String, TimetableModel>> timetableAsync;
  final DateTime      selectedDate;
  final bool          isAdmin;
  final Function(String, int, SlotModel) onEdit;
  final Function(String, int) onDelete;
  final Function(String) onAdd;

  const _SlotListSliver({
    required this.timetableAsync,
    required this.selectedDate,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return timetableAsync.when(
      loading: () => const SliverFillRemaining(child: Center(child: CardShimmerList(count: 3))),
      error:   (e, _) => SliverFillRemaining(child: ErrorStateWidget(message: e.toString())),
      data: (data) {
        final day = DateFormat('EEEE').format(selectedDate); // e.g., "Monday"
        final slots = data[day]?.slots ?? [];

        if (slots.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateWidget(
              icon:    Icons.event_available_outlined,
              title:   'No Classes',
              message: 'Relax! No classes for $day.',
              actionLabel: isAdmin ? '+ Add Slot' : null,
              onAction: isAdmin ? () => onAdd(day) : null,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.xxl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Determine if this is the last item for timeline styling
                final isLast = index == slots.length - 1;
                return SlotCard(
                  slot:     slots[index],
                  index:    index,
                  isAdmin:  isAdmin,
                  isLast:   isLast, // New property for timeline
                  onEdit:   () => onEdit(day, index, slots[index]),
                  onDelete: () => onDelete(day, index),
                );
              },
              childCount: slots.length,
            ),
          ),
        );
      },
    );
  }
}

// ── AddEdit bottom sheet ──────────────────────────────────────

class AddEditSlotSheet extends ConsumerStatefulWidget {
  final String   day;
  final int?     slotIndex;
  final dynamic  existing; // SlotModel?

  const AddEditSlotSheet({
    super.key,
    required this.day,
    this.slotIndex,
    this.existing,
  });

  @override
  ConsumerState<AddEditSlotSheet> createState() => _AddEditSlotSheetState();
}

class _AddEditSlotSheetState extends ConsumerState<AddEditSlotSheet> {
  late String _day;
  final _subjectCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _roomCtrl    = TextEditingController();
  final _sectionCtrl = TextEditingController();
  String _type       = 'lecture';
  String _startTime  = '09:00';
  String _endTime    = '10:00';

  bool get _isEdit => widget.slotIndex != null;

  @override
  void initState() {
    super.initState();
    _day = widget.day;
    if (widget.existing != null) {
      final s            = widget.existing!;
      _subjectCtrl.text  = s.subject;
      _teacherCtrl.text  = s.teacher;
      _roomCtrl.text     = s.room;
      _sectionCtrl.text  = s.section;
      _type              = s.type;
      _startTime         = s.startTime;
      _endTime           = s.endTime;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _teacherCtrl.dispose();
    _roomCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final initial = TimeOfDay(
      hour:   int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context:     context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx)
            .copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty) {
      context.showError('Subject name is required.');
      return;
    }
    if (_startTime.compareTo(_endTime) >= 0) {
      context.showError('End time must be after start time.');
      return;
    }

    final slot = SlotModel(
      startTime: _startTime,
      endTime:   _endTime,
      subject:   _subjectCtrl.text.trim(),
      teacher:   _teacherCtrl.text.trim(),
      room:      _roomCtrl.text.trim(),
      section:   _sectionCtrl.text.trim(),
      type:      _type,
    );

    final ctrl = ref.read(timetableControllerProvider.notifier);

    if (_isEdit) {
      await ctrl.editSlot(_day, widget.slotIndex!, slot);
    } else {
      await ctrl.addSlot(_day, slot);
    }

    if (mounted) {
      final err = ref.read(timetableControllerProvider).error;
      if (err != null) {
        context.showError(err);
      } else {
        context.showSuccess(_isEdit ? 'Slot updated!' : 'Slot added!');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.isDark;
    final crudState = ref.watch(timetableControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.lg, AppSizes.md, AppSizes.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ────────────────────────────────────
          Center(
            child: Container(
              width:  48,
              height: 4,
              decoration: BoxDecoration(
                color:        isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            _isEdit ? 'Edit Class Slot' : 'Add Class Slot',
            style: context.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Day selector ───────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kWeekDays.map((d) {
                final sel = _day == d;
                return GestureDetector(
                  onTap: () => setState(() => _day = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: AppSizes.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary
                          : (isDark ? AppColors.cardDark : AppColors.cardLight),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusRound),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.dividerDark
                                : AppColors.dividerLight),
                      ),
                    ),
                    child: Text(
                      d.substring(0, 3),
                      style: TextStyle(
                        color:      sel ? Colors.white : null,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        fontSize:   13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Time row ───────────────────────────────────────
          Row(
            children: [
              Expanded(child: _TimeButton(
                label: 'Start',
                time:  _startTime,
                onTap: () => _pickTime(isStart: true),
                isDark: isDark,
              )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                child: Text('–', style: context.textTheme.titleLarge),
              ),
              Expanded(child: _TimeButton(
                label: 'End',
                time:  _endTime,
                onTap: () => _pickTime(isStart: false),
                isDark: isDark,
              )),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // ── Subject ────────────────────────────────────────
          TextField(
            controller:     _subjectCtrl,
            decoration: InputDecoration(
              labelText:   'Subject *',
              hintText:    'e.g. Data Structures',
              prefixIcon:  const Icon(Icons.book_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Teacher ────────────────────────────────────────
          TextField(
            controller:     _teacherCtrl,
            decoration: InputDecoration(
              labelText:   'Teacher',
              hintText:    'Prof. Name',
              prefixIcon:  const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Room & Section row ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _roomCtrl,
                  decoration: InputDecoration(
                    labelText:  'Room',
                    hintText:   'T-201',
                    prefixIcon: const Icon(Icons.room_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: TextField(
                  controller: _sectionCtrl,
                  decoration: InputDecoration(
                    labelText:  'Section',
                    hintText:   'e.g. A, B',
                    prefixIcon: const Icon(Icons.group_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // ── Type selector ──────────────────────────────────
          Wrap(
            spacing: AppSizes.sm,
            children: ['lecture','lab','tutorial','break'].map((t) {
              final sel   = _type == t;
              final color = switch (t) {
                'lab'      => AppColors.success,
                'tutorial' => AppColors.warning,
                'break'    => AppColors.textSecondaryLight,
                _          => AppColors.primary,
              };
              return ChoiceChip(
                label:       Text(t.toUpperCase()),
                selected:    sel,
                onSelected:  (_) => setState(() => _type = t),
                selectedColor: color,
                labelStyle:  TextStyle(
                  color:      sel ? Colors.white : null,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  fontSize:   11,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.md),

          const SizedBox(height: AppSizes.md),

          // ── Save button ────────────────────────────────────
          SizedBox(
            width:  double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: crudState.isSaving ? null : _submit,
              child: crudState.isSaving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(_isEdit ? 'Update Slot' : 'Add Slot'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time picker button ────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  final String   label;
  final String   time;
  final VoidCallback onTap;
  final bool     isDark;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText:   label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            prefixIcon: const Icon(Icons.access_time_outlined),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.md),
            filled:    true,
            fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          ),
          child: Text(time,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class _SectionChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _SectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize:   12,
          ),
        ),
      ),
    );
  }
}
