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
import '../controllers/announcement_controller.dart';
import '../widgets/announcement_card.dart';

class AnnouncementListScreen extends ConsumerStatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  ConsumerState<AnnouncementListScreen> createState() =>
      _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends ConsumerState<AnnouncementListScreen> {
  @override
  void dispose() {
    // When leaving the screen, update the "last check" timestamp.
    // Future.microtask is used to avoid modifying state during widget disposal lifecycle.
    Future.microtask(() => ref.read(lastReadAnnouncementsProvider.notifier).markAllRead());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark           = context.isDark;
    final isAdmin          = ref.watch(isAdminProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    // Listen for save/delete outcome
    ref.listen(announcementControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(announcementControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess('Done!');
        ref.read(announcementControllerProvider.notifier).resetState();
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even when empty
          slivers: [
            // ── SliverAppBar ────────────────────────────────────
            SliverAppBar(
              pinned:         true,
              floating:       true,
            snap:           true,
            expandedHeight: 100,
            backgroundColor:
                isDark ? AppColors.cardDark : AppColors.surfaceLight,
            elevation: 0,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                  left: AppSizes.md, bottom: AppSizes.md),
              title: Text(
                '📢  Announcements',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon:    const Icon(Icons.add_rounded),
                  tooltip: 'New Announcement',
                  onPressed: () => context.push('/home/announcements/add'),
                ),
              const SizedBox(width: AppSizes.xs),
            ],
          ),

          // ── Body ────────────────────────────────────────────
          switch (announcementsAsync) {
            AsyncLoading() => const SliverFillRemaining(
                child: Center(child: CardShimmerList(count: 5))),
            AsyncError(:final error) => SliverFillRemaining(
                child: ErrorStateWidget(message: error.toString())),
            AsyncData(:final value) => value.isEmpty
                ? const SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon:    Icons.campaign_outlined,
                      title:   'No Announcements',
                      message: 'Announcements from admin will appear here.',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.md, AppSizes.sm,
                        AppSizes.md, AppSizes.xxl),
                    sliver: SliverList.builder(
                      itemCount:   value.length,
                      itemBuilder: (_, i) => AnnouncementCard(
                        announcement: value[i],
                        index:        i,
                        isAdmin:      isAdmin,
                      ),
                    ),
                  ),
            _ => const SliverToBoxAdapter(),
          },
        ],
      ),
    ),
    floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag:   'fab_announcements',
              onPressed: () => context.push('/home/announcements/add'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
