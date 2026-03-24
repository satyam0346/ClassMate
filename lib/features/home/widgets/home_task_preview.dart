import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../features/tasks/controllers/task_controller.dart';
import '../../../shared/widgets/app_chips.dart';
import '../../../shared/widgets/loading_shimmer.dart';

/// Shows the next 3 upcoming (non-overdue, non-done) tasks on the dashboard.
class HomeTaskPreview extends ConsumerWidget {
  const HomeTaskPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final preview    = ref.watch(upcomingTasksPreviewProvider);
    final isDark     = context.isDark;

    if (tasksAsync.isLoading) {
      return const TaskShimmerList(count: 3);
    }
    if (tasksAsync.hasError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
            SizedBox(height: AppSizes.sm),
            Text('Could not load tasks.', textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (preview.isEmpty) {
      return Container(
        width:   double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.success, size: 32),
            SizedBox(height: AppSizes.sm),
            Text('All caught up! No pending tasks. 🎉',
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final task in preview)
          Container(
            margin:  const EdgeInsets.only(bottom: AppSizes.sm),
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset:     const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left: priority indicator dot
                Container(
                  width:  10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (task.priority) {
                      'high'   => AppColors.priorityHigh,
                      'medium' => AppColors.priorityMedium,
                      _        => AppColors.priorityLow,
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title.truncate(50),
                        style: context.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (task.subject.isNotEmpty)
                        Text(task.subject,
                            style: context.textTheme.bodySmall),
                    ],
                  ),
                ),
                DueDateBadge(
                    dueDate: task.dueDate,
                    isOverdue: task.isOverdue),
              ],
            ),
          ),
        TextButton(
          onPressed: () => context.go('/home/tasks'),
          child: Text(
            'View all tasks →',
            style: TextStyle(
              color:      isDark ? AppColors.accent : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
