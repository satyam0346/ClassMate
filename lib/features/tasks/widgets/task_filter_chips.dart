import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/task_controller.dart';

/// Horizontal scrolling filter chips for the task list screen.
class TaskFilterChips extends ConsumerWidget {
  const TaskFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(taskFilterProvider);
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: TaskFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (_, i) {
          final filter   = TaskFilter.values[i];
          final selected = current == filter;

          return ChoiceChip(
            label: Text(filter.label),
            selected: selected,
            onSelected: (_) =>
                ref.read(taskFilterProvider.notifier).state = filter,
            selectedColor:   isDark ? AppColors.accent : AppColors.primary,
            backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            labelStyle: TextStyle(
              color: selected
                  ? (isDark ? AppColors.primaryDark : Colors.white)
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontSize:   13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              side: BorderSide(
                color: selected
                    ? Colors.transparent
                    : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: 4),
          );
        },
      ),
    );
  }
}
