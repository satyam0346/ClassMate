import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data model for an exam entry.
class ExamModel {
  final String   id;
  final String   subject;
  final DateTime examDate;     // Date AND time of the exam
  final String   venue;
  final String   notes;
  final String   createdBy;
  final bool     isOfficial;   // Admin-posted official exam
  final String   type;         // "theory" | "practical" | "quiz" | "viva"
  final int      durationMins; // Duration in minutes

  const ExamModel({
    required this.id,
    required this.subject,
    required this.examDate,
    required this.venue,
    required this.notes,
    required this.createdBy,
    required this.isOfficial,
    this.type         = 'theory',
    this.durationMins = 180,
  });

  // ── Computed ─────────────────────────────────────────────

  bool get isUpcoming  => examDate.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return examDate.year  == now.year  &&
           examDate.month == now.month &&
           examDate.day   == now.day;
  }
  bool get isPast => examDate.isBefore(DateTime.now());

  /// Full countdown until exam start.
  Duration get timeRemaining {
    final diff = examDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get daysRemaining => timeRemaining.inDays;

  /// Urgency level — drives colour coding.
  /// 0 = today/past, 1 = 1–2 days, 2 = 3–7 days, 3 = 7+ days.
  int get urgency {
    if (!isUpcoming)        return 0;
    if (daysRemaining == 0) return 0;
    if (daysRemaining <= 2) return 1;
    if (daysRemaining <= 7) return 2;
    return 3;
  }

  // ── Serialisation ─────────────────────────────────────────

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExamModel(
      id:           doc.id,
      subject:      d['subject']      as String? ?? '',
      examDate:     (d['examDate']    as Timestamp?)?.toDate() ?? DateTime.now(),
      venue:        d['venue']        as String? ?? '',
      notes:        d['notes']        as String? ?? '',
      createdBy:    d['createdBy']    as String? ?? '',
      isOfficial:   d['isOfficial']   as bool?   ?? false,
      type:         d['type']         as String? ?? 'theory',
      durationMins: d['durationMins'] as int?    ?? 180,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'subject':      subject,
        'examDate':     Timestamp.fromDate(examDate),
        'venue':        venue,
        'notes':        notes,
        'createdBy':    createdBy,
        'isOfficial':   isOfficial,
        'type':         type,
        'durationMins': durationMins,
      };

  ExamModel copyWith({
    String?   subject,
    DateTime? examDate,
    String?   venue,
    String?   notes,
    bool?     isOfficial,
    String?   type,
    int?      durationMins,
  }) =>
      ExamModel(
        id:           id,
        subject:      subject      ?? this.subject,
        examDate:     examDate     ?? this.examDate,
        venue:        venue        ?? this.venue,
        notes:        notes        ?? this.notes,
        createdBy:    createdBy,
        isOfficial:   isOfficial   ?? this.isOfficial,
        type:         type         ?? this.type,
        durationMins: durationMins ?? this.durationMins,
      );
}
