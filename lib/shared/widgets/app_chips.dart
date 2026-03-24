import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Priority chip — coloured pill label for task priority.
class PriorityChip extends StatelessWidget {
  final String priority; // "high" | "medium" | "low"

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'high'   => AppColors.priorityHigh,
      'medium' => AppColors.priorityMedium,
      'low'    => AppColors.priorityLow,
      _        => AppColors.textSecondaryLight,
    };
    final label = switch (priority) {
      'high'   => '🔴 High',
      'medium' => '🟡 Medium',
      'low'    => '🟢 Low',
      _        => priority,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  final String status; // "pending" | "in_progress" | "done"

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'done'        => (AppColors.success, '✓ Done'),
      'in_progress' => (AppColors.info,    '⏳ In Progress'),
      _             => (AppColors.warning, '⏺ Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Role badge ────────────────────────────────────────────────

class RoleBadge extends StatelessWidget {
  final bool isAdmin;
  const RoleBadge({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color:        isAdmin
            ? AppColors.accent.withOpacity(0.15)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border:       Border.all(
          color: isAdmin
              ? AppColors.accent.withOpacity(0.5)
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        isAdmin ? '👑 Admin' : '🎓 Student',
        style: TextStyle(
          color:      isAdmin ? AppColors.accent : AppColors.primary,
          fontSize:   11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Due date badge ────────────────────────────────────────────

class DueDateBadge extends StatelessWidget {
  final DateTime dueDate;
  final bool     isOverdue;

  const DueDateBadge({
    super.key,
    required this.dueDate,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? AppColors.error : AppColors.textSecondaryLight;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '${dueDate.day} ${_month(dueDate.month)} ${dueDate.year}',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _month(int m) => const [
    '', 'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ][m];
}
