import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../controllers/exam_controller.dart';
import '../widgets/exam_card.dart';

class ExamListScreen extends ConsumerWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark     = context.isDark;
    final isAdmin    = ref.watch(isAdminProvider);
    final allAsync   = ref.watch(allExamsProvider);
    final upcoming   = ref.watch(upcomingExamsProvider);
    final past       = ref.watch(pastExamsProvider);

    // Show save/delete outcomes
    ref.listen(examControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(examControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess('Done!');
        ref.read(examControllerProvider.notifier).resetState();
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              pinned:          true,
              floating:        true,
              snap:            true,
              expandedHeight:  100,
              backgroundColor:
                  isDark ? AppColors.cardDark : AppColors.surfaceLight,
              elevation: 0,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(
                    left: AppSizes.md, bottom: AppSizes.md),
                title: Text(
                  '📝  Exams',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              actions: [
                if (isAdmin)
                  IconButton(
                    icon:    const Icon(Icons.add_rounded),
                    tooltip: 'Add Exam',
                    onPressed: () =>
                        context.push('/home/exams/add'),
                  ),
                const SizedBox(width: AppSizes.xs),
              ],
              bottom: TabBar(
                indicatorColor:       isDark ? AppColors.accent : AppColors.primary,
                indicatorWeight:      3,
                labelColor:           isDark ? AppColors.accent : AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ],
          body: switch (allAsync) {
            AsyncLoading() => const Center(
                child: CardShimmerList(count: 4),
              ),
            AsyncError(:final error) => ErrorStateWidget(
                message: error.toString(),
              ),
            _ => TabBarView(
                children: [
                  // ── Upcoming tab ─────────────────────────────────
                  upcoming.isEmpty
                      ? const EmptyStateWidget(
                          icon:    Icons.event_available_outlined,
                          title:   'No Upcoming Exams',
                          message:
                              'When exams are added they will appear here.',
                          iconColor: AppColors.success,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              AppSizes.md, AppSizes.md,
                              AppSizes.md, AppSizes.xxl),
                          itemCount: upcoming.length,
                          itemBuilder: (_, i) => ExamCard(
                            exam:             upcoming[i],
                            index:            i,
                            showAdminActions: isAdmin,
                          ),
                        ),

                  // ── Past tab ──────────────────────────────────────
                  past.isEmpty
                      ? const EmptyStateWidget(
                          icon:    Icons.history_edu_outlined,
                          title:   'No Past Exams',
                          message: 'Completed exams will show here.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              AppSizes.md, AppSizes.md,
                              AppSizes.md, AppSizes.xxl),
                          itemCount: past.length,
                          itemBuilder: (_, i) => ExamCard(
                            exam:    past[i],
                            index:   i,
                            showAdminActions: isAdmin,
                          ),
                        ),
                ],
              ),
          },
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                heroTag:   'fab_exams',
                onPressed: () => context.push('/home/exams/add'),
                child:     const Icon(Icons.add_rounded),
              )
            : null,
      ),
    );
  }
}
