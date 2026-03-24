import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../announcements/controllers/announcement_controller.dart';

/// Shows the latest 3 announcements on the home dashboard.
/// Uses the shared [latestAnnouncementsProvider] from the announcement controller.
class HomeAnnouncementPreview extends ConsumerWidget {
  const HomeAnnouncementPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark           = context.isDark;
    final announcementsAsync = ref.watch(announcementsProvider);

    return announcementsAsync.when(
      loading: () => const CardShimmerList(count: 2),
      error:   (_, __) => const SizedBox.shrink(),
      data: (all) {
        final list = all.take(3).toList();

        if (list.isEmpty) {
          return Container(
            width:   double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color:        isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight),
            ),
            child: const Text(
              'No announcements yet. 📢',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: [
            ...list.asMap().entries.map((entry) {
              final i   = entry.key;
              final ann = entry.value;
              return GestureDetector(
                onTap: () => context.push(
                    '/home/announcements/${ann.id}', extra: ann),
                child: Container(
                  margin:  const EdgeInsets.only(bottom: AppSizes.sm),
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: ann.isPinned
                          ? AppColors.accent.withOpacity(0.35)
                          : (isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight),
                      width: ann.isPinned ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width:  40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: ann.isPinned
                                ? [AppColors.accent.withOpacity(0.7),
                                   AppColors.primary]
                                : [AppColors.primary.withOpacity(0.8),
                                   AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end:   Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (ann.isPinned) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('📌',
                                        style: TextStyle(fontSize: 9)),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    ann.title.truncate(60),
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ann.createdAt.relative,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondaryLight, size: 20),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 60 * i))
                    .slideX(begin: 0.03),
              );
            }),
            TextButton(
              onPressed: () => context.go('/home/announcements'),
              child: Text(
                'View all announcements →',
                style: TextStyle(
                  color:      isDark ? AppColors.accent : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
