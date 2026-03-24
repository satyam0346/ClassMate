import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../features/exams/controllers/exam_controller.dart';
import '../../../shared/widgets/loading_shimmer.dart';

/// Featured countdown card for the NEXT upcoming exam — shown on home dashboard.
/// Refactored to be much more compact (horizontal layout).
class HomeExamCountdownCard extends ConsumerStatefulWidget {
  const HomeExamCountdownCard({super.key});

  @override
  ConsumerState<HomeExamCountdownCard> createState() =>
      _HomeExamCountdownCardState();
}

class _HomeExamCountdownCardState extends ConsumerState<HomeExamCountdownCard> {
  Timer? _countdownTimer;
  Timer? _sliderTimer;
  late PageController _pageController;
  int _examCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _pageController.hasClients && _examCount > 1) {
        int nextPage = (_pageController.page!.round() + 1) % _examCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutBack,
        );
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(allExamsProvider);
    final upcomingExams = ref.watch(upcomingExamsProvider);
    final isDark = context.isDark;

    if (examsAsync.isLoading) {
      return const ShimmerBox(width: double.infinity, height: 105);
    }

    if (upcomingExams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration_outlined,
                color: AppColors.success, size: 24),
            const SizedBox(width: AppSizes.md),
            const Expanded(
              child: Text('No upcoming exams! 🎉',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            TextButton(
              onPressed: () => context.go('/home/exams'),
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    _examCount = upcomingExams.length;

    return SizedBox(
      height: 105,
      child: PageView.builder(
        controller: _pageController,
        itemCount: upcomingExams.length,
        itemBuilder: (context, index) {
          final exam = upcomingExams[index];
          final remainingRaw = exam.timeRemaining;
          final remaining =
              remainingRaw.isNegative ? Duration.zero : remainingRaw;

          final urgColor = exam.isToday
              ? AppColors.error
              : (exam.daysRemaining <= 3 ? AppColors.warning : AppColors.info);

          final days = remaining.inDays;
          final hours = remaining.inHours % 24;
          final mins = remaining.inMinutes % 60;
          final secs = remaining.inSeconds % 60;

          final showHMS = days == 0;

          return GestureDetector(
            onTap: () => context.go('/home/exams'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg, vertical: AppSizes.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    urgColor.withOpacity(isDark ? 0.25 : 0.08),
                    urgColor.withOpacity(isDark ? 0.1 : 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                border: Border.all(color: urgColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        exam.isToday
                            ? '🚨 EXAM TODAY'
                            : (index == 0 ? 'NEXT EXAM' : 'UPCOMING EXAM'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: urgColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        showHMS ? 'Starting soon' : 'in $days Days',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: urgColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.subject,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${exam.examDate.formattedDateTime} • ${exam.venue}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall
                                  ?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      if (showHMS)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CountdownSegment(
                                value: hours, label: 'H', color: urgColor),
                            _Separator(color: urgColor),
                            _CountdownSegment(
                                value: mins, label: 'M', color: urgColor),
                            _Separator(color: urgColor),
                            _CountdownSegment(
                                value: secs, label: 'S', color: urgColor),
                          ],
                        )
                      else
                        Text(
                          '$days Days',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: urgColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 50.ms).slideX(begin: 0.02);
  }
}

class _Separator extends StatelessWidget {
  final Color color;
  const _Separator({required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(':',
            style: TextStyle(
                color: color.withOpacity(0.5),
                fontWeight: FontWeight.w900,
                fontSize: 16)),
      );
}

class _CountdownSegment extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _CountdownSegment({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color.withOpacity(0.6),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
