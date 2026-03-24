import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../shared/models/exam_model.dart';

// ── Stream providers ──────────────────────────────────────────

/// All exams sorted by examDate ascending.
final allExamsProvider = StreamProvider<List<ExamModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('exams')
      .orderBy('examDate')
      .snapshots()
      .map((s) => s.docs.map(ExamModel.fromFirestore).toList());
});

/// Only future exams.
final upcomingExamsProvider = Provider<List<ExamModel>>((ref) {
  final all = ref.watch(allExamsProvider).valueOrNull ?? [];
  return all.where((e) => e.isUpcoming).toList();
});

/// Only past exams (most-recent first).
final pastExamsProvider = Provider<List<ExamModel>>((ref) {
  final all = ref.watch(allExamsProvider).valueOrNull ?? [];
  return all.where((e) => e.isPast).toList().reversed.toList();
});

/// The immediately next exam — used on home dashboard.
final nextExamProvider = Provider<ExamModel?>((ref) {
  final upcoming = ref.watch(upcomingExamsProvider);
  return upcoming.isEmpty ? null : upcoming.first;
});

/// Count of upcoming exams — for home quick stats.
final upcomingExamCountProvider = Provider<int>((ref) {
  return ref.watch(upcomingExamsProvider).length;
});

// ── CRUD state ────────────────────────────────────────────────

class ExamCrudState {
  final bool   isSaving;
  final bool   isDeleting;
  final String? error;
  final bool   success;

  const ExamCrudState({
    this.isSaving   = false,
    this.isDeleting = false,
    this.error,
    this.success    = false,
  });

  ExamCrudState copyWith({
    bool?   isSaving,
    bool?   isDeleting,
    String? error,
    bool?   success,
  }) =>
      ExamCrudState(
        isSaving:   isSaving   ?? this.isSaving,
        isDeleting: isDeleting ?? this.isDeleting,
        error:      error,
        success:    success    ?? this.success,
      );

  ExamCrudState reset() => const ExamCrudState();
}

// ── Controller ────────────────────────────────────────────────

class ExamController extends StateNotifier<ExamCrudState> {
  ExamController() : super(const ExamCrudState());

  final _fs  = FirestoreService.instance;
  final _ntf = NotificationService.instance;

  // ── Notification IDs (deterministic per exam) ─────────────

  /// Notification ID for the 24h-before alert.
  static int _id24h(String examId) => examId.hashCode.abs() % 100000 + 100000;

  /// Notification ID for the 1h-before alert.
  static int _id1h(String examId)  => examId.hashCode.abs() % 100000 + 200000;

  // ── Create ────────────────────────────────────────────────

  Future<void> createExam({
    required String   subject,
    required DateTime examDate,
    required String   venue,
    required String   notes,
    required String   type,
    required int      durationMins,
    required bool     isOfficial,
    required String   createdBy,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final data = {
        'subject':      InputSanitizer.sanitizeTitle(subject),
        'examDate':     examDate,
        'venue':        InputSanitizer.sanitizeText(venue),
        'notes':        InputSanitizer.sanitizeDescription(notes),
        'type':         type,
        'durationMins': durationMins,
        'isOfficial':   isOfficial,
        'createdBy':    createdBy,
      };

      final ref = await _fs.add('exams',
          ExamModel(
            id:           '',
            subject:      data['subject']      as String,
            examDate:     examDate,
            venue:        data['venue']        as String,
            notes:        data['notes']        as String,
            type:         type,
            durationMins: durationMins,
            isOfficial:   isOfficial,
            createdBy:    createdBy,
          ).toFirestore());

      await _scheduleNotifications(ref.id, data['subject'] as String, examDate);
      state = state.copyWith(isSaving: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Update ────────────────────────────────────────────────

  Future<void> updateExam(ExamModel exam) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _fs.update('exams/${exam.id}', exam.toFirestore());
      // Re-schedule notifications for new date
      await _cancelNotifications(exam.id);
      await _scheduleNotifications(exam.id, exam.subject, exam.examDate);
      state = state.copyWith(isSaving: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteExam(String id) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      await _cancelNotifications(id);
      await _fs.delete('exams/$id');
      state = state.copyWith(isDeleting: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isDeleting: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Notification scheduling ───────────────────────────────

  Future<void> _scheduleNotifications(
      String id, String subject, DateTime examDate) async {
    if (examDate.isBefore(DateTime.now())) return;
    try {
      // 24 hours before
      final t24h = examDate.subtract(const Duration(hours: 24));
      if (t24h.isAfter(DateTime.now())) {
        await _ntf.scheduleNotification(
          id:            _id24h(id),
          title:         '📝 Exam Tomorrow!',
          body:          '$subject – ${_formatDate(examDate)}',
          scheduledDate: t24h,
          payload:       id,
        );
      }

      // 1 hour before
      final t1h = examDate.subtract(const Duration(hours: 1));
      if (t1h.isAfter(DateTime.now())) {
        await _ntf.scheduleNotification(
          id:            _id1h(id),
          title:         '⏰ Exam in 1 Hour!',
          body:          '$subject – Don\'t forget your hall ticket!',
          scheduledDate: t1h,
          payload:       id,
        );
      }
    } catch (e) {
      debugPrint('[ExamCtrl] Notification scheduling failed (non-fatal): $e');
    }
  }

  Future<void> _cancelNotifications(String id) async {
    try {
      await _ntf.cancel(_id24h(id));
      await _ntf.cancel(_id1h(id));
    } catch (e) {
      debugPrint('[ExamCtrl] Notification cancel failed (non-fatal): $e');
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour, m = dt.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12  = h % 12 == 0 ? 12 : h % 12;
    return '${dt.day} ${months[dt.month - 1]}, $h12:$m $amPm';
  }

  void resetState() => state = state.reset();
}

final examControllerProvider =
    StateNotifierProvider.autoDispose<ExamController, ExamCrudState>(
  (_) => ExamController(),
);
