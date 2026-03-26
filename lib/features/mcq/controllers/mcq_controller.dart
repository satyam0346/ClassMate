import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mcq_question.dart';
import '../data/bes_questions.dart';

// ── State ─────────────────────────────────────────────────────

class McqSessionState {
  final List<McqQuestion> shuffled;
  final int currentIndex;
  final Map<int, String> answers;    // index → chosen answer
  final Set<int> bookmarks;          // question ids
  final int xp;
  final int streak;
  final int bestStreak;
  final bool sessionDone;
  final int totalXpAllTime;
  final int totalCorrectAllTime;
  final int totalAttemptedAllTime;
  final Set<int> bookmarksAllTime;   // persisted across sessions

  const McqSessionState({
    this.shuffled         = const [],
    this.currentIndex     = 0,
    this.answers          = const {},
    this.bookmarks        = const {},
    this.xp               = 0,
    this.streak           = 0,
    this.bestStreak       = 0,
    this.sessionDone      = false,
    this.totalXpAllTime   = 0,
    this.totalCorrectAllTime    = 0,
    this.totalAttemptedAllTime  = 0,
    this.bookmarksAllTime = const {},
  });

  McqQuestion? get currentQuestion =>
      shuffled.isEmpty ? null : shuffled[currentIndex];
  int get answeredCount  => answers.length;
  int get correctCount   =>
      answers.entries.where((e) => shuffled[e.key].answer == e.value).length;
  int get wrongCount     => answeredCount - correctCount;
  bool get isAnswered    => answers.containsKey(currentIndex);
  String? get chosenAnswer => answers[currentIndex];

  McqSessionState copyWith({
    List<McqQuestion>? shuffled,
    int? currentIndex,
    Map<int, String>? answers,
    Set<int>? bookmarks,
    int? xp,
    int? streak,
    int? bestStreak,
    bool? sessionDone,
    int? totalXpAllTime,
    int? totalCorrectAllTime,
    int? totalAttemptedAllTime,
    Set<int>? bookmarksAllTime,
  }) => McqSessionState(
    shuffled:              shuffled          ?? this.shuffled,
    currentIndex:          currentIndex      ?? this.currentIndex,
    answers:               answers           ?? this.answers,
    bookmarks:             bookmarks         ?? this.bookmarks,
    xp:                    xp               ?? this.xp,
    streak:                streak           ?? this.streak,
    bestStreak:            bestStreak       ?? this.bestStreak,
    sessionDone:           sessionDone      ?? this.sessionDone,
    totalXpAllTime:        totalXpAllTime        ?? this.totalXpAllTime,
    totalCorrectAllTime:   totalCorrectAllTime   ?? this.totalCorrectAllTime,
    totalAttemptedAllTime: totalAttemptedAllTime ?? this.totalAttemptedAllTime,
    bookmarksAllTime:      bookmarksAllTime ?? this.bookmarksAllTime,
  );
}

// ── Controller ────────────────────────────────────────────────

class McqController extends StateNotifier<McqSessionState> {
  McqController() : super(const McqSessionState()) {
    _loadPersisted();
  }

  static const _kXpKey       = 'mcq_total_xp';
  static const _kCorrectKey  = 'mcq_total_correct';
  static const _kAttemptKey  = 'mcq_total_attempted';
  static const _kBookmarkKey = 'mcq_bookmarks';

  // ── Persistence ────────────────────────────────────────────

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final xp       = prefs.getInt(_kXpKey)      ?? 0;
    final correct  = prefs.getInt(_kCorrectKey) ?? 0;
    final attempt  = prefs.getInt(_kAttemptKey) ?? 0;
    final bmList   = prefs.getStringList(_kBookmarkKey) ?? [];
    final bms      = bmList.map((s) => int.tryParse(s) ?? -1).where((i) => i != -1).toSet();
    state = state.copyWith(
      totalXpAllTime: xp,
      totalCorrectAllTime: correct,
      totalAttemptedAllTime: attempt,
      bookmarksAllTime: bms,
    );
  }

  Future<void> _savePersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kXpKey,      state.totalXpAllTime);
    await prefs.setInt(_kCorrectKey, state.totalCorrectAllTime);
    await prefs.setInt(_kAttemptKey, state.totalAttemptedAllTime);
    await prefs.setStringList(
        _kBookmarkKey, state.bookmarksAllTime.map((i) => i.toString()).toList());
  }

  // ── Session ────────────────────────────────────────────────

  void startSession() {
    final rng = Random();
    final list = [...kBesQuestions]..shuffle(rng);
    state = state.copyWith(
      shuffled:    list,
      currentIndex: 0,
      answers:     {},
      bookmarks:   {},
      xp:         0,
      streak:     0,
      bestStreak: 0,
      sessionDone: false,
    );
  }

  void selectAnswer(String chosen) {
    if (state.isAnswered) return;
    final q       = state.currentQuestion!;
    final correct = chosen == q.answer;

    final newAnswers = {...state.answers, state.currentIndex: chosen};
    final newStreak  = correct ? state.streak + 1 : 0;
    final newBest    = newStreak > state.bestStreak ? newStreak : state.bestStreak;
    final xpGain     = correct ? 10 + (newStreak > 1 ? min(newStreak * 2, 20) : 0) : 0;
    final newXp      = (state.xp + xpGain).clamp(0, 999999) as int;

    state = state.copyWith(
      answers:    newAnswers,
      streak:     newStreak,
      bestStreak: newBest,
      xp:         newXp,
    );
  }

  void goNext() {
    if (!state.isAnswered) return;
    if (state.currentIndex < state.shuffled.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      _finishSession();
    }
  }

  void goBack() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void _finishSession() {
    final newTotalXp      = state.totalXpAllTime + state.xp;
    final newTotalCorrect = state.totalCorrectAllTime + state.correctCount;
    final newTotalAttempt = state.totalAttemptedAllTime + state.answeredCount;
    state = state.copyWith(
      sessionDone:           true,
      totalXpAllTime:        newTotalXp,
      totalCorrectAllTime:   newTotalCorrect,
      totalAttemptedAllTime: newTotalAttempt,
    );
    _savePersisted();
  }

  void toggleBookmark(int questionId) {
    final sessionBms = {...state.bookmarks};
    final allBms     = {...state.bookmarksAllTime};
    if (sessionBms.contains(questionId)) {
      sessionBms.remove(questionId);
      allBms.remove(questionId);
    } else {
      sessionBms.add(questionId);
      allBms.add(questionId);
    }
    state = state.copyWith(bookmarks: sessionBms, bookmarksAllTime: allBms);
    _savePersisted();
  }

  void removeBookmark(int questionId) {
    final sessionBms = {...state.bookmarks}..remove(questionId);
    final allBms     = {...state.bookmarksAllTime}..remove(questionId);
    state = state.copyWith(bookmarks: sessionBms, bookmarksAllTime: allBms);
    _savePersisted();
  }

  Future<void> resetAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kXpKey);
    await prefs.remove(_kCorrectKey);
    await prefs.remove(_kAttemptKey);
    await prefs.remove(_kBookmarkKey);
    state = state.copyWith(
      shuffled:              [],
      currentIndex:          0,
      answers:               {},
      bookmarks:             {},
      xp:                    0,
      streak:                0,
      bestStreak:            0,
      sessionDone:           false,
      totalXpAllTime:        0,
      totalCorrectAllTime:   0,
      totalAttemptedAllTime: 0,
      bookmarksAllTime:      {},
    );
  }
}

// ── Providers ─────────────────────────────────────────────────

final mcqControllerProvider =
    StateNotifierProvider<McqController, McqSessionState>(
  (_) => McqController(),
);

/// Expose bookmarked questions for the Bookmarks tab.
final mcqBookmarkedQuestionsProvider = Provider<List<McqQuestion>>((ref) {
  final bms = ref.watch(mcqControllerProvider).bookmarksAllTime;
  return kBesQuestions.where((q) => bms.contains(q.id)).toList();
});
