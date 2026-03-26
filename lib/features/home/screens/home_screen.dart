import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../features/tasks/controllers/task_controller.dart';
import '../../../features/exams/controllers/exam_controller.dart';
import '../../../features/mcq/providers/mcq_feature_provider.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../widgets/greeting_card.dart';
import '../widgets/home_task_preview.dart';
import '../widgets/home_announcement_preview.dart';
import '../widgets/home_timetable_card.dart';
import '../widgets/home_exam_countdown_card.dart';
import '../widgets/home_materials_preview.dart';
import '../widgets/home_mcq_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync    = ref.watch(userModelProvider);
    final isDark       = context.isDark;
    final pendingCount = ref.watch(pendingTaskCountProvider);
    final overdueCount = ref.watch(overdueTaskCountProvider);
    final examCount    = ref.watch(upcomingExamCountProvider);
    final mcqEnabled   = ref.watch(mcqFeatureEnabledProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Gradient SliverAppBar ────────────────────────────────
          SliverAppBar(
            pinned:         false,
            floating:       true,
            snap:           true,
            expandedHeight: 60,
            backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            elevation:      0,
            title: userAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => Text('ClassMate', style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              data: (user) => Row(
                children: [
                  Text(
                    'Hi, ${(user?.name.split(' ').first) ?? 'there'} 👋',
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize:   18,
                    ),
                  ),
                  if (user?.isAdmin == true) ...[
                    const SizedBox(width: AppSizes.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:        AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                      ),
                      child: const Text('👑 Admin',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                onPressed: () => context.push('/home/announcements'),
              ),
              const SizedBox(width: AppSizes.xs),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting card ──────────────────────────────────
                  const GreetingCard()
                      .animate()
                      .fadeIn(delay: 50.ms)
                      .slideY(begin: 0.05),
                  const SizedBox(height: AppSizes.md),

                  // ── Quick stats row ────────────────────────────────
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 32 - 16) / 3,
                        child: _StatCard(
                          icon:    Icons.pending_actions_rounded,
                          label:   'Pending',
                          value:   '$pendingCount',
                          color:   AppColors.warning,
                          onTap:   () => context.go('/home/tasks'),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 32 - 16) / 3,
                        child: _StatCard(
                          icon:    Icons.warning_amber_rounded,
                          label:   'Overdue',
                          value:   '$overdueCount',
                          color:   AppColors.error,
                          onTap:   () => context.go('/home/tasks'),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 32 - 16) / 3,
                        child: _StatCard(
                          icon:    Icons.quiz_outlined,
                          label:   'Exams',
                          value:   '$examCount',
                          color:   AppColors.info,
                          onTap:   () => context.go('/home/exams'),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: AppSizes.lg),

                  // ── Today's timetable ───────────────────────────
                  _SectionHeader(
                    title:  'Today\'s Classes',
                    seeAll: () => context.go('/home/timetable'),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: AppSizes.sm),
                  const HomeTimetableCard()
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: AppSizes.lg),

                  // ── Next exam countdown ────────────────────────────
                  _SectionHeader(
                    title:  'Next Exam',
                    seeAll: () => context.go('/home/exams'),
                  ).animate().fadeIn(delay: 280.ms),
                  const SizedBox(height: AppSizes.sm),
                  const HomeExamCountdownCard()
                      .animate()
                      .fadeIn(delay: 320.ms),
                  const SizedBox(height: AppSizes.lg),

                  // ── BES MCQ Practice card (Remote Config gated) ─────
                  if (mcqEnabled) ...[
                    _SectionHeader(
                      title:  'BES Practice',
                      seeAll: () => context.go('/home/mcq'),
                    ).animate().fadeIn(delay: 195.ms),
                    const SizedBox(height: AppSizes.sm),
                    const HomeMcqCard()
                        .animate()
                        .fadeIn(delay: 220.ms),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  // ── Recent materials preview ─────────────────────
                  _SectionHeader(
                    title:  'Study Materials',
                    seeAll: () => context.go('/home/materials'),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: AppSizes.sm),
                  const HomeMaterialsPreview()
                      .animate()
                      .fadeIn(delay: 250.ms),
                  const SizedBox(height: AppSizes.lg),

                  // ── Upcoming tasks preview ─────────────────────────
                  _SectionHeader(
                    title:  'Upcoming Tasks',
                    seeAll: () => context.go('/home/tasks'),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: AppSizes.sm),
                  const HomeTaskPreview()
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: AppSizes.lg),

                  // ── Recent announcements preview ───────────────────
                  _SectionHeader(
                    title:  'Announcements',
                    seeAll: () => context.go('/home/announcements'),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: AppSizes.sm),
                  const HomeAnnouncementPreview()
                      .animate()
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick stat card ───────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          boxShadow: [
            BoxShadow(
              color:      color.withOpacity(0.08),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              value,
              style: TextStyle(
                color:      color,
                fontSize:   26,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback seeAll;

  const _SectionHeader({required this.title, required this.seeAll});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title,
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton(
            onPressed: seeAll,
            child: Text(
              'See all →',
              style: TextStyle(
                color: context.isDark ? AppColors.accent : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize:   13,
              ),
            ),
          ),
        ],
      );
}
