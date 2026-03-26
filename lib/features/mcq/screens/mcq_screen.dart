import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../controllers/mcq_controller.dart';
import '../data/bes_questions.dart';
import '../models/mcq_question.dart';

class McqScreen extends ConsumerStatefulWidget {
  const McqScreen({super.key});

  @override
  ConsumerState<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends ConsumerState<McqScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showXpToast = false;
  int _lastXp = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerXpToast(int pts) {
    if (pts <= 0) return;
    setState(() {
      _showXpToast = true;
      _lastXp = pts;
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showXpToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg     = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BES MCQ Practice',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Basics of Environmental Studies',
                style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          Consumer(builder: (_, ref, __) {
            final xp = ref.watch(mcqControllerProvider).xp;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('⚡ $xp XP',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            );
          }),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Practice'),
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Dashboard'),
            Tab(icon: Icon(Icons.bookmark_rounded, size: 18), text: 'Bookmarks'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PracticeTab(onXpEarned: _triggerXpToast),
              const _DashboardTab(),
              const _BookmarksTab(),
            ],
          ),
          // XP toast
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: _showXpToast ? 12 : -60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12)
                ],
              ),
              child: Text('+$_lastXp XP',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PRACTICE TAB
// ══════════════════════════════════════════════════════════════

class _PracticeTab extends ConsumerWidget {
  final void Function(int pts) onXpEarned;
  const _PracticeTab({required this.onXpEarned});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl  = ref.watch(mcqControllerProvider);
    final notif = ref.read(mcqControllerProvider.notifier);

    if (ctrl.shuffled.isEmpty) return _StartScreen(notif: notif);
    if (ctrl.sessionDone)      return _DoneScreen(ctrl: ctrl, notif: notif);
    return _QuizView(ctrl: ctrl, notif: notif, onXpEarned: onXpEarned);
  }
}

// ── START SCREEN ──────────────────────────────────────────────

class _StartScreen extends StatelessWidget {
  final McqController notif;
  const _StartScreen({required this.notif});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.heroGradient,
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                boxShadow: [BoxShadow(
                  color: AppColors.primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)
                )],
              ),
              child: const Icon(Icons.quiz_rounded, size: 52, color: Colors.white),
            )
                .animate()
                .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 600.ms),
            const SizedBox(height: 24),
            Text('BES Practice',
                style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text('${kBesQuestions.length} questions · Gamified · Reshuffled every session',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ))
                .animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 12),
            // Topic chips
            Wrap(
              spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
              children: ['Ecology', 'Ecosystems', 'Degradation', 'Settlements', 'Population', 'Resources', 'Env Education']
                  .map((t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
                  .toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: notif.startSession,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Practice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                ),
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

// ── QUIZ VIEW ─────────────────────────────────────────────────

class _QuizView extends ConsumerStatefulWidget {
  final McqSessionState ctrl;
  final McqController notif;
  final void Function(int) onXpEarned;
  const _QuizView({required this.ctrl, required this.notif, required this.onXpEarned});

  @override
  ConsumerState<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends ConsumerState<_QuizView> {
  int _prevXp = 0;

  @override
  void didUpdateWidget(_QuizView old) {
    super.didUpdateWidget(old);
    // Fire XP toast only when XP actually increases — not on every build
    final newXp = widget.ctrl.xp;
    if (newXp > _prevXp) {
      widget.onXpEarned(newXp - _prevXp);
      _prevXp = newXp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl    = widget.ctrl;
    final notif   = widget.notif;
    final isDark  = context.isDark;
    final q       = ctrl.currentQuestion!;
    final total   = ctrl.shuffled.length;
    final pct     = ctrl.currentIndex / total;
    final bm      = ctrl.bookmarks.contains(q.id) || ctrl.bookmarksAllTime.contains(q.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${ctrl.currentIndex + 1}/$total',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  )),
            ],
          ),
          const SizedBox(height: 12),

          // Question card
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 16, offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                      ),
                      child: Text(q.topic,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => notif.toggleBookmark(q.id),
                      child: Icon(
                        bm ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: bm ? AppColors.warning : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(q.question,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600, height: 1.45,
                    )),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.06),
          const SizedBox(height: 14),

          // Options
          ..._buildOptions(context, q, ctrl, notif, isDark),
          const SizedBox(height: 14),

          // Feedback
          if (ctrl.isAnswered) _FeedbackBanner(ctrl: ctrl, q: q),

          const SizedBox(height: 14),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: ctrl.currentIndex > 0 ? notif.goBack : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                    side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                    foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: ctrl.isAnswered ? notif.goNext : null,
                  icon: Icon(
                    ctrl.currentIndex == total - 1
                        ? Icons.flag_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(ctrl.currentIndex == total - 1 ? 'Finish 🎉' : 'Next'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                    disabledForegroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(
    BuildContext context,
    McqQuestion q,
    McqSessionState ctrl,
    McqController notif,
    bool isDark,
  ) {
    const letters = ['A', 'B', 'C', 'D'];
    return List.generate(q.options.length, (i) {
      final option     = q.options[i];
      final isChosen   = ctrl.chosenAnswer == option;
      final isCorrect  = option == q.answer;
      final revealed   = ctrl.isAnswered;

      Color borderCol = isDark ? AppColors.dividerDark : AppColors.dividerLight;
      Color bgCol     = isDark ? AppColors.cardDark    : AppColors.surfaceLight;
      Color textCol   = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      Color letterBg  = isDark ? AppColors.dividerDark : AppColors.backgroundLight;
      Color letterFg  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

      if (revealed) {
        if (isCorrect) {
          borderCol = AppColors.success;
          bgCol     = AppColors.success.withOpacity(0.1);
          letterBg  = AppColors.success;
          letterFg  = Colors.white;
          textCol   = AppColors.success;
        } else if (isChosen) {
          borderCol = AppColors.error;
          bgCol     = AppColors.error.withOpacity(0.08);
          letterBg  = AppColors.error;
          letterFg  = Colors.white;
          textCol   = AppColors.error;
        }
      } else if (isChosen) {
        borderCol = AppColors.primary;
        bgCol     = AppColors.primary.withOpacity(0.08);
        letterBg  = AppColors.primary;
        letterFg  = Colors.white;
        textCol   = AppColors.primary;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: revealed ? null : () => notif.selectAnswer(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: borderCol, width: 1.5),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
                  child: Center(
                    child: Text(letters[i],
                        style: TextStyle(
                          color: letterFg, fontSize: 12, fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(option,
                      style: TextStyle(
                        color: textCol, fontSize: 14, fontWeight: FontWeight.w500,
                      )),
                ),
                if (revealed && isCorrect)
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                if (revealed && isChosen && !isCorrect)
                  const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
              ],
            ),
          )
              .animate(key: ValueKey('opt_${q.id}_$i'))
              .fadeIn(delay: (i * 40).ms)
              .slideX(begin: 0.05),
        ),
      );
    });
  }
}

// ── FEEDBACK BANNER ───────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final McqSessionState ctrl;
  final McqQuestion q;
  const _FeedbackBanner({required this.ctrl, required this.q});

  @override
  Widget build(BuildContext context) {
    final correct = ctrl.chosenAnswer == q.answer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: correct
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: correct ? AppColors.success.withOpacity(0.4) : AppColors.error.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
            color: correct ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              correct
                  ? '✅  Correct! Well done.'
                  : '❌  Incorrect. Correct answer: ${q.answer}',
              style: TextStyle(
                color: correct ? AppColors.success : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ── DONE SCREEN ───────────────────────────────────────────────

class _DoneScreen extends StatelessWidget {
  final McqSessionState ctrl;
  final McqController notif;
  const _DoneScreen({required this.ctrl, required this.notif});

  @override
  Widget build(BuildContext context) {
    final total   = ctrl.shuffled.length;
    final correct = ctrl.correctCount;
    final pct     = total > 0 ? (correct / total * 100).round() : 0;
    final trophy  = pct >= 90 ? '🏆' : pct >= 70 ? '🥇' : pct >= 50 ? '🥈' : '📚';
    final msg     = pct >= 90 ? 'Outstanding!' : pct >= 70 ? 'Great job!' : pct >= 50 ? 'Good effort!' : 'Keep practicing!';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(trophy, style: const TextStyle(fontSize: 64))
              .animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 16),
          Text(msg, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 4),
          Text('You completed all $total questions',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ))
              .animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 24),
          Row(
            children: [
              _DoneStat(label: 'Correct', value: '$correct', color: AppColors.success),
              const SizedBox(width: 10),
              _DoneStat(label: 'Wrong', value: '${ctrl.wrongCount}', color: AppColors.error),
              const SizedBox(width: 10),
              _DoneStat(label: 'Score', value: '$pct%', color: AppColors.primary),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.heroGradient),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Column(
              children: [
                Text('⚡ ${ctrl.xp} XP earned  ·  🔥 ${ctrl.bestStreak} best streak',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Total All-Time: ${ctrl.totalXpAllTime} XP · ${ctrl.totalCorrectAllTime} correct / ${ctrl.totalAttemptedAllTime}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: notif.startSession,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Practice Again (Reshuffled)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }
}

class _DoneStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DoneStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ══════════════════════════════════════════════════════════════

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl   = ref.watch(mcqControllerProvider);
    final notif  = ref.read(mcqControllerProvider.notifier);
    final isDark = context.isDark;
    final total  = kBesQuestions.length;
    final done   = ctrl.answeredCount;
    final correct = ctrl.correctCount;
    final wrong  = ctrl.wrongCount;
    final accuracy = done > 0 ? (correct / done * 100).round() : 0;
    final allAcc = ctrl.totalAttemptedAllTime > 0
        ? (ctrl.totalCorrectAllTime / ctrl.totalAttemptedAllTime * 100).round()
        : 0;

    final badges = [
      _BadgeData(icon: '🌱', label: 'First Step', earned: ctrl.totalAttemptedAllTime >= 1),
      _BadgeData(icon: '🔥', label: 'On Fire',    earned: ctrl.bestStreak >= 5),
      _BadgeData(icon: '⚡', label: '100 XP',     earned: ctrl.totalXpAllTime >= 100),
      _BadgeData(icon: '🏆', label: 'Half Done',  earned: ctrl.totalAttemptedAllTime >= total ~/ 2),
      _BadgeData(icon: '🎯', label: 'Sharp Eye',  earned: allAcc >= 80 && ctrl.totalAttemptedAllTime >= 10),
      _BadgeData(icon: '🌟', label: 'Star',       earned: ctrl.totalXpAllTime >= 500),
      _BadgeData(icon: '📚', label: 'All Done',   earned: ctrl.sessionDone),
      _BadgeData(icon: '💎', label: 'Perfect',    earned: allAcc == 100 && ctrl.totalAttemptedAllTime >= 20),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
            childAspectRatio: 1.6,
            children: [
              _DashStat(label: 'Total XP',   value: '${ctrl.totalXpAllTime}',  color: AppColors.primary),
              _DashStat(label: '🔥 Streak',   value: '${ctrl.streak}',          color: AppColors.warning),
              _DashStat(label: '✅ Correct',  value: '$correct',                color: AppColors.success),
              _DashStat(label: '❌ Wrong',    value: '$wrong',                  color: AppColors.error),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: AppSizes.md),

          // Session progress
          _ProgressCard(
            title: 'Session Progress',
            subtitle: '$done / $total',
            value: done / total,
            color: AppColors.primary,
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 10),
          _ProgressCard(
            title: 'Session Accuracy',
            subtitle: '$accuracy%',
            value: accuracy / 100,
            color: AppColors.success,
          ).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: AppSizes.md),

          // Best streak box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Column(
              children: [
                Text('🔥 ${ctrl.bestStreak}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
                const Text('Best Streak This Session',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: AppSizes.md),

          // Achievements
          Text('Achievements',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: badges.length,
            itemBuilder: (_, i) {
              final b = badges[i];
              return Container(
                decoration: BoxDecoration(
                  color: b.earned
                      ? AppColors.primary.withOpacity(0.1)
                      : (isDark ? AppColors.cardDark : AppColors.cardLight),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: b.earned
                        ? AppColors.primary.withOpacity(0.3)
                        : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 3),
                    Text(b.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: b.earned
                              ? AppColors.primary
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        )),
                  ],
                ),
              ).animate().fadeIn(delay: (200 + i * 30).ms);
            },
          ),
          const SizedBox(height: AppSizes.md),

          // Reset button
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, notif),
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 18),
            label: const Text('Reset All Stats', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, McqController notif) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all stats?'),
        content: const Text('This will clear your XP, progress, and bookmarks permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { Navigator.pop(context); notif.resetAllStats(); },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _BadgeData {
  final String icon; final String label; final bool earned;
  const _BadgeData({required this.icon, required this.label, required this.earned});
}

class _DashStat extends StatelessWidget {
  final String label; final String value; final Color color;
  const _DashStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title; final String subtitle; final double value; final Color color;
  const _ProgressCard({required this.title, required this.subtitle, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BOOKMARKS TAB
// ══════════════════════════════════════════════════════════════

class _BookmarksTab extends ConsumerWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notif   = ref.read(mcqControllerProvider.notifier);
    final bms     = ref.watch(mcqBookmarkedQuestionsProvider);
    final isDark  = context.isDark;

    if (bms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_outline_rounded, size: 56, color: AppColors.warning),
            const SizedBox(height: 12),
            Text('No bookmarks yet', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Tap 🔖 on any question to save it here for review.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                )),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: bms.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('${bms.length} bookmarked question${bms.length > 1 ? 's' : ''}',
                style: context.textTheme.bodySmall),
          );
        }
        final q = bms[i - 1];
        return Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(q.topic,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => notif.removeBookmark(q.id),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(q.question,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.4)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(q.answer,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.05);
      },
    );
  }
}
