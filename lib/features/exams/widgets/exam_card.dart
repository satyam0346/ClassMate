import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/exam_model.dart';
import '../controllers/exam_controller.dart';
import '../../../shared/widgets/app_chips.dart';
import '../../../shared/widgets/confirmation_dialog.dart';

/// Full-featured exam card with live countdown timer.
class ExamCard extends ConsumerStatefulWidget {
  final ExamModel exam;
  final int       index;
  final bool      showAdminActions;

  const ExamCard({
    super.key,
    required this.exam,
    required this.index,
    this.showAdminActions = false,
  });

  @override
  ConsumerState<ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends ConsumerState<ExamCard> {
  late Timer   _timer;
  Duration     _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.exam.timeRemaining;
    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _remaining = widget.exam.timeRemaining);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.isDark;
    final exam     = widget.exam;
    final urgColor = _urgencyColor(exam.urgency);
    final isAdmin  = widget.showAdminActions;
    final isToday  = exam.isToday;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isToday
              ? urgColor.withOpacity(0.6)
              : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color:      urgColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset:     const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color:      Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                )
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: subject + type badge ────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject icon container
                Container(
                  width:  48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:        urgColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    _typeIcon(exam.type),
                    color: urgColor,
                    size:  24,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.subject,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TypeBadge(type: exam.type, color: urgColor),
                          if (exam.isOfficial) ...[
                            const SizedBox(width: AppSizes.sm),
                            _OfficialBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Countdown badge (top-right)
                if (exam.isUpcoming)
                  _CountdownBadge(remaining: _remaining, color: urgColor),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // ── Date, venue, duration row ─────────────────────────
            _InfoRow(icon: Icons.calendar_today_outlined,
                     text: exam.examDate.formattedDateTime),
            const SizedBox(height: 6),
            if (exam.venue.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, text: exam.venue),
            if (exam.venue.isNotEmpty) const SizedBox(height: 6),
            _InfoRow(icon: Icons.timer_outlined,
                     text: _formatDuration(exam.durationMins)),

            if (exam.notes.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                exam.notes.truncate(100),
                style: context.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],

            // ── TODAY label ───────────────────────────────────────
            if (isToday) ...[
              const SizedBox(height: AppSizes.sm),
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:        urgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  '🚨 EXAM TODAY — Best of luck!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:      urgColor,
                    fontWeight: FontWeight.w700,
                    fontSize:   13,
                  ),
                ),
              ),
            ],

            // ── Admin actions ─────────────────────────────────────
            if (isAdmin) ...[
              const SizedBox(height: AppSizes.xs),
              Divider(height: 1,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push(
                        '/home/exams/edit/${exam.id}', extra: exam),
                    icon:  const Icon(Icons.edit_outlined,
                        size: 15, color: AppColors.info),
                    label: const Text('Edit',
                        style: TextStyle(color: AppColors.info, fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(context, ref, exam.id),
                    icon:  const Icon(Icons.delete_outline_rounded,
                        size: 15, color: AppColors.error),
                    label: const Text('Delete',
                        style: TextStyle(color: AppColors.error, fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * widget.index))
        .slideY(begin: 0.06);
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final ok = await showConfirmationDialog(
      context:       context,
      title:         'Delete Exam',
      message:       'Remove "${widget.exam.subject}" from the exam tracker?',
      confirmLabel:  'Delete',
      isDestructive: true,
    );
    if (ok && mounted) {
      ref.read(examControllerProvider.notifier).deleteExam(id);
    }
  }

  Color _urgencyColor(int urgency) => switch (urgency) {
    0 => AppColors.error,
    1 => AppColors.warning,
    2 => AppColors.info,
    _ => AppColors.success,
  };

  IconData _typeIcon(String type) => switch (type) {
    'practical' => Icons.science_outlined,
    'quiz'      => Icons.quiz_outlined,
    'viva'      => Icons.record_voice_over_outlined,
    _           => Icons.menu_book_outlined, // theory
  };

  String _formatDuration(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '$m min';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ── Countdown badge ───────────────────────────────────────────

class _CountdownBadge extends StatelessWidget {
  final Duration remaining;
  final Color    color;

  const _CountdownBadge({required this.remaining, required this.color});

  @override
  Widget build(BuildContext context) {
    final days  = remaining.inDays;
    final hours = remaining.inHours % 24;
    final mins  = remaining.inMinutes % 60;
    final secs  = remaining.inSeconds % 60;

    final String label;
    if (days > 0) {
      label = '${days}d ${hours}h';
    } else if (hours > 0) {
      label = '${hours}h ${mins}m';
    } else if (mins > 0) {
      label = '${mins}m ${secs}s';
    } else {
      label = '${secs}s';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            border:       Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:      color,
              fontSize:   12,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('remaining',
            style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7))),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon,
              size:  14,
              color: context.isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color  color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'practical' => '🔬 Practical',
      'quiz'      => '📝 Quiz',
      'viva'      => '🎤 Viva',
      _           => '📚 Theory',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border:       Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(
            color:      color,
            fontSize:   10,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}

class _OfficialBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          border:       Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: const Text('✅ Official',
            style: TextStyle(
              color:      AppColors.accent,
              fontSize:   10,
              fontWeight: FontWeight.w700,
            )),
      );
}
