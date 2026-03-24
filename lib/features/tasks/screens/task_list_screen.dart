import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../controllers/task_controller.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_chips.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTasksProvider);
    final isDark        = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────
          SliverAppBar(
            pinned:          true,
            floating:        true,
            snap:            true,
            expandedHeight:  110,
            backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            elevation:       0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                  left: AppSizes.md, bottom: AppSizes.md),
              title: const Text(
                '✅  Tasks',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add Task',
                onPressed: () => context.push('/home/tasks/add'),
              ),
              const SizedBox(width: AppSizes.xs),
            ],
          ),

          // ── Filter chips ─────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              child: Container(
                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                child: const TaskFilterChips(),
              ),
            ),
          ),

          // ── Task list ────────────────────────────────────────────
          switch (filteredAsync) {
            AsyncLoading() => const SliverFillRemaining(
                child: Center(
                  child: TaskShimmerList(),
                ),
              ),
            AsyncError(:final error) => SliverFillRemaining(
                child: ErrorStateWidget(message: error.toString()),
              ),
            AsyncData(:final value) => value.isEmpty
                ? SliverFillRemaining(
                    child: NoTasksEmpty(
                      onAdd: () => context.push('/home/tasks/add'),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.md, AppSizes.sm,
                        AppSizes.md, AppSizes.xxl),
                    sliver: SliverList.builder(
                      itemCount: value.length,
                      itemBuilder: (_, i) =>
                          TaskCard(task: value[i], index: i),
                    ),
                  ),
            _ => const SliverToBoxAdapter(),
          },
        ],
      ),
    );
  }
}

// ── Persistent header delegate for filter bar ─────────────────

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _FilterHeaderDelegate({required this.child});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(_, __, ___) => child;

  @override
  bool shouldRebuild(_) => true;
}
