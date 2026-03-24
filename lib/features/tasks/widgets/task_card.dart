import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/task_model.dart';
import '../../../shared/widgets/app_chips.dart';
import '../controllers/task_controller.dart';

/// A single task card with swipe-to-delete and tap-to-detail.
class TaskCard extends ConsumerWidget {
  final TaskModel task;
  final int       index;

  const TaskCard({super.key, required this.task, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Dismissible(
      key:             Key('task_${task.id}'),
      direction:       DismissDirection.endToStart,
      confirmDismiss:  (_) => _confirmDelete(context),
      onDismissed:     (_) =>
          ref.read(taskControllerProvider.notifier).deleteTask(task.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: AppSizes.lg),
        decoration: BoxDecoration(
          color:        AppColors.error.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: const Column(
          mainAxisSize:      MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => context.push('/home/tasks/${task.id}', extra: task),
        child: Container(
          margin:  const EdgeInsets.symmetric(vertical: AppSizes.xs / 2),
          decoration: BoxDecoration(
            color:        isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority colour bar (4px left edge)
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    borderRadius: const BorderRadius.only(
                      topLeft:    Radius.circular(AppSizes.radiusLg),
                      bottomLeft: Radius.circular(AppSizes.radiusLg),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: title + status toggle
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight:     FontWeight.w700,
                                  decoration:     task.status == 'done'
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.status == 'done'
                                      ? (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight)
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            // Done toggle checkbox
                            GestureDetector(
                              onTap: () => ref
                                  .read(taskControllerProvider.notifier)
                                  .toggleStatus(task),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width:  26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: task.status == 'done'
                                      ? AppColors.success
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: task.status == 'done'
                                        ? AppColors.success
                                        : (isDark
                                            ? AppColors.dividerDark
                                            : AppColors.dividerLight),
                                    width: 2,
                                  ),
                                ),
                                child: task.status == 'done'
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Subject + description
                        if (task.subject.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                              const SizedBox(width: 4),
                              Text(
                                task.subject,
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description.truncate(80),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSizes.sm),

                        // Bottom row: due date + priority + class badge
                        Row(
                          children: [
                            DueDateBadge(
                              dueDate:   task.dueDate,
                              isOverdue: task.isOverdue,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            PriorityChip(priority: task.priority),
                            const Spacer(),
                            if (task.isClassTask)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:        AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusRound),
                                  border: Border.all(
                                      color: AppColors.info.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  '🏫 Class',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:     AppColors.info,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.04),
      ),
    );
  }

  Color _priorityColor(String p) => switch (p) {
    'high'   => AppColors.priorityHigh,
    'medium' => AppColors.priorityMedium,
    'low'    => AppColors.priorityLow,
    _        => AppColors.textSecondaryLight,
  };

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
