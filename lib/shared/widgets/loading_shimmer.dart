import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

// ── Generic shimmer wrapper ───────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double  width;
  final double  height;
  final double  borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSizes.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor:      isDark ? const Color(0xFF2C2C3E) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF3C3C50) : Colors.grey[100]!,
      child: Container(
        width:        width,
        height:       height,
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Profile card shimmer ──────────────────────────────────────

class ProfileShimmerCard extends StatelessWidget {
  final double height;
  const ProfileShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:       height,
      padding:      const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color:        Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          ShimmerBox(width: 40, height: 40, borderRadius: AppSizes.radiusSm),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 80,  height: 10, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerBox(width: 160, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task card shimmer ─────────────────────────────────────────

class TaskShimmerList extends StatelessWidget {
  final int count;
  const TaskShimmerList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics:    const NeverScrollableScrollPhysics(),
      itemCount:  count,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSizes.sm),
      itemBuilder: (_, i) => _TaskShimmerCard(index: i),
    );
  }
}

class _TaskShimmerCard extends StatelessWidget {
  final int index;
  const _TaskShimmerCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:      const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(
                width: 80 + (index % 3) * 20.0,
                height: 12,
                borderRadius: 4,
              ),
              const Spacer(),
              ShimmerBox(width: 60, height: 22, borderRadius: AppSizes.radiusRound),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
          const SizedBox(height: 6),
          ShimmerBox(width: 180, height: 10, borderRadius: 4),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              ShimmerBox(width: 100, height: 10, borderRadius: 4),
              const Spacer(),
              ShimmerBox(width: 70, height: 10, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Material / Announcement shimmer ──────────────────────────

class CardShimmerList extends StatelessWidget {
  final int count;
  const CardShimmerList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      shrinkWrap: true,
      physics:    const NeverScrollableScrollPhysics(),
      itemCount:  count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(
              width: 220 + (i % 2) * 40.0,
              height: 16,
              borderRadius: 4,
            ),
            const SizedBox(height: 8),
            ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
            const SizedBox(height: 6),
            ShimmerBox(width: 160, height: 10, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
