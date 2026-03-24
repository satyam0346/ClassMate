import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../features/timetable/controllers/timetable_controller.dart';
import '../../../shared/widgets/loading_shimmer.dart';

/// Compact horizontal scroll of today's timetable slots for the home dashboard.
class HomeTimetableCard extends ConsumerWidget {
  const HomeTimetableCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableStreamProvider);
    final todaySlots     = ref.watch(todayTimetableProvider);
    final isDark         = context.isDark;

    if (timetableAsync.isLoading) {
      return SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
          itemBuilder: (_, __) => const ShimmerBox(width: 130, height: 96),
        ),
      );
    }

    if (todaySlots.isEmpty) {
      return Container(
        width:   double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined,
                color: AppColors.success, size: 24),
            const SizedBox(width: AppSizes.md),
            const Expanded(
              child: Text('No classes today! 🎉',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: () => context.go('/home/timetable'),
              child: Text(
                'Full Schedule',
                style: TextStyle(
                  color:      isDark ? AppColors.accent : AppColors.primary,
                  fontSize:   12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection:  Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount:        todaySlots.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
            itemBuilder: (_, i) {
              final slot    = todaySlots[i];
              final isActive = slot.isCurrentlyActive;
              final typeColor = switch (slot.type) {
                'lab'      => AppColors.success,
                'tutorial' => AppColors.warning,
                'break'    => AppColors.textSecondaryLight,
                _          => AppColors.primary,
              };

              return GestureDetector(
                onTap: () => context.go('/home/timetable'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width:   130,
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: isActive
                        ? typeColor.withOpacity(isDark ? 0.2 : 0.08)
                        : (isDark ? AppColors.cardDark : AppColors.cardLight),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: isActive
                          ? typeColor.withOpacity(0.6)
                          : (isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:      typeColor.withOpacity(0.2),
                              blurRadius: 10,
                              offset:     const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isActive)
                            Container(
                              width:  7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: typeColor,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              slot.startTime,
                              style: TextStyle(
                                fontSize:   11,
                                color:      isActive ? typeColor : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        slot.subject,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      slot.isOver
                              ? (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (slot.room.isNotEmpty)
                        Text(
                          '📍 ${slot.room}',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color:    isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () => context.go('/home/timetable'),
          child: Text(
            'View full timetable →',
            style: TextStyle(
              color:      isDark ? AppColors.accent : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize:   13,
            ),
          ),
        ),
      ],
    );
  }
}
