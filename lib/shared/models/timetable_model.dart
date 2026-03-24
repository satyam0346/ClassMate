import 'package:cloud_firestore/cloud_firestore.dart';

/// A single time slot within a day's timetable.
class SlotModel {
  final String startTime;  // "09:00" (24-h, for sorting)
  final String endTime;    // "10:00"
  final String subject;
  final String room;
  final String teacher;
  final String type;       // "lecture" | "lab" | "tutorial" | "break"
  final String section;    // "A", "B", "B1", etc.

  const SlotModel({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.room,
    required this.teacher,
    this.type    = 'lecture',
    this.section = '',
  });

  factory SlotModel.fromMap(Map<String, dynamic> map) => SlotModel(
        startTime: map['startTime'] as String? ?? map['time'] as String? ?? '',
        endTime:   map['endTime']   as String? ?? '',
        subject:   map['subject']   as String? ?? '',
        room:      map['room']      as String? ?? '',
        teacher:   map['teacher']   as String? ?? '',
        type:      map['type']      as String? ?? 'lecture',
        section:   map['section']   as String? ?? map['labGroup'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'startTime': startTime,
        'endTime':   endTime,
        'subject':   subject,
        'room':      room,
        'teacher':   teacher,
        'type':      type,
        'section':   section,
      };

  SlotModel copyWith({
    String? startTime,
    String? endTime,
    String? subject,
    String? room,
    String? teacher,
    String? type,
    String? section,
  }) =>
      SlotModel(
        startTime: startTime ?? this.startTime,
        endTime:   endTime   ?? this.endTime,
        subject:   subject   ?? this.subject,
        room:      room      ?? this.room,
        teacher:   teacher   ?? this.teacher,
        type:      type      ?? this.type,
        section:   section   ?? this.section,
      );

  // ── Helpers ────────────────────────────────────────────────

  /// Formatted display string: "09:00 – 10:00".
  String get timeRange => '$startTime – $endTime';

  /// Duration in minutes based on startTime/endTime strings.
  int get durationMinutes {
    try {
      final s = _parseTime(startTime);
      final e = _parseTime(endTime);
      return e - s;
    } catch (_) {
      return 0;
    }
  }

  /// Returns true if the current wall-clock time falls within this slot.
  bool get isCurrentlyActive {
    try {
      final now  = DateTime.now();
      final nowM = now.hour * 60 + now.minute;
      final start = _parseTime(startTime);
      final end   = _parseTime(endTime);
      return nowM >= start && nowM < end;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the slot is already over today.
  bool get isOver {
    try {
      final now  = DateTime.now();
      final nowM = now.hour * 60 + now.minute;
      return _parseTime(endTime) <= nowM;
    } catch (_) {
      return false;
    }
  }

  static int _parseTime(String t) {
    // Accepts "HH:mm" — e.g. "09:00", "14:30"
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

/// Firestore data model for one day's full timetable.
/// Document ID == day name, e.g. "Monday".
class TimetableModel {
  final String          id;    // doc ID == day name
  final String          day;   // "Monday" display label
  final List<SlotModel> slots; // sorted by startTime

  const TimetableModel({
    required this.id,
    required this.day,
    required this.slots,
  });

  factory TimetableModel.fromFirestore(DocumentSnapshot doc) {
    final d       = doc.data() as Map<String, dynamic>;
    final rawSlots = d['slots'] as List<dynamic>? ?? [];
    final slots   = rawSlots
        .map((s) => SlotModel.fromMap(s as Map<String, dynamic>))
        .toList()
      // Sort by startTime ascending
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return TimetableModel(
      id:    doc.id,
      day:   d['day'] as String? ?? doc.id,
      slots: slots,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'day':   day,
        'slots': slots.map((s) => s.toMap()).toList(),
      };

  TimetableModel copyWith({List<SlotModel>? slots}) => TimetableModel(
        id:    id,
        day:   day,
        slots: slots ?? this.slots,
      );
}
