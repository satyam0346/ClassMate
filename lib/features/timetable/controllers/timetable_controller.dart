import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/models/timetable_model.dart';

// ── Constants ─────────────────────────────────────────────────

const kWeekDays = [
  'Monday', 'Tuesday', 'Wednesday',
  'Thursday', 'Friday', 'Saturday',
];

// ── Stream providers ──────────────────────────────────────────

/// Stream all 6 day documents from /timetable.
/// Returns a map: day-name → TimetableModel.
final timetableStreamProvider =
    StreamProvider<Map<String, TimetableModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('timetable')
      .snapshots()
      .map((snap) {
    final map = <String, TimetableModel>{};
    for (final doc in snap.docs) {
      map[doc.id] = TimetableModel.fromFirestore(doc);
    }
    return map;
  });
});

/// Today's timetable — used on the home dashboard.
final todayTimetableProvider = Provider<List<SlotModel>>((ref) {
  final timetableAsync = ref.watch(timetableStreamProvider);
  final timetable      = timetableAsync.valueOrNull ?? {};
  final todayName      = kWeekDays[(() {
    final w = DateTime.now().weekday; // 1=Mon…7=Sun
    return w > 6 ? 5 : w - 1;        // Saturday cap at index 5
  })()];
  return timetable[todayName]?.slots ?? [];
});

/// Timetable for a specific day — used in the day tab view.
final dayTimetableProvider = Provider.family<List<SlotModel>, String>((ref, day) {
  final timetableAsync = ref.watch(timetableStreamProvider);
  return timetableAsync.valueOrNull?[day]?.slots ?? [];
});

// ── Current day index ─────────────────────────────────────────

/// 0 = Monday … 5 = Saturday. Clamped so Sunday shows Saturday.
int get todayWeekIndex {
  final w = DateTime.now().weekday; // 1=Mon, 7=Sun
  return (w - 1).clamp(0, 5);
}

// ── CRUD State ────────────────────────────────────────────────

class TimetableCrudState {
  final bool   isSaving;
  final String? error;
  final bool   success;

  const TimetableCrudState({
    this.isSaving = false,
    this.error,
    this.success  = false,
  });

  TimetableCrudState copyWith({bool? isSaving, String? error, bool? success}) =>
      TimetableCrudState(
        isSaving: isSaving ?? this.isSaving,
        error:    error,
        success:  success  ?? this.success,
      );
  TimetableCrudState reset() => const TimetableCrudState();
}

// ── Controller ────────────────────────────────────────────────

class TimetableController extends StateNotifier<TimetableCrudState> {
  TimetableController() : super(const TimetableCrudState());

  final _fs   = FirestoreService.instance;
  final _dio  = Dio();

  /// Add a slot to a day's timetable.
  Future<void> addSlot(String day, SlotModel slot) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final doc     = await _fs.getDoc('timetable/$day');
      List<SlotModel> existing = [];
      if (doc.exists) {
        final timetable = TimetableModel.fromFirestore(doc);
        existing        = List.from(timetable.slots);
      }
      existing.add(slot);
      // Sort ascending by startTime after adding
      existing.sort((a, b) => a.startTime.compareTo(b.startTime));

      await _fs.set('timetable/$day', {
        'day':   day,
        'slots': existing.map((s) => s.toMap()).toList(),
      });
      state = state.copyWith(isSaving: false, success: true);
      
      // Auto-notify users of the change
      // Auto-notify users of the change
      final groupStr = slot.section.isNotEmpty ? ' (Sec. ${slot.section})' : '';
      _notifyUpdate('New $groupStr Added', '${slot.subject}$groupStr added to $day schedule.');
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Edit slot at [index] for a given day.
  Future<void> editSlot(String day, int index, SlotModel updated) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final doc = await _fs.getDoc('timetable/$day');
      if (!doc.exists) throw Exception('Day not found in timetable.');
      final timetable = TimetableModel.fromFirestore(doc);
      final slots     = List<SlotModel>.from(timetable.slots);
      if (index < 0 || index >= slots.length) {
        throw Exception('Invalid slot index.');
      }
      slots[index] = updated;
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));

      await _fs.update('timetable/$day', {
        'slots': slots.map((s) => s.toMap()).toList(),
      });
      state = state.copyWith(isSaving: false, success: true);

      // Auto-notify users of the change
      final groupStr = updated.section.isNotEmpty ? ' (Sec. ${updated.section})' : '';
      _notifyUpdate('Timetable Updated', '${updated.subject}$groupStr on $day was modified.');
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Remove slot at [index] for a given day.
  Future<void> deleteSlot(String day, int index) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final doc = await _fs.getDoc('timetable/$day');
      if (!doc.exists) return;
      final timetable = TimetableModel.fromFirestore(doc);
      final slots     = List<SlotModel>.from(timetable.slots)..removeAt(index);

      await _fs.update('timetable/$day', {
        'slots': slots.map((s) => s.toMap()).toList(),
      });
      state = state.copyWith(isSaving: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }


  void resetState() => state = state.reset();

  // ── Notification Logic ────────────────────────────────────

  /// Sends a push notification and creates a system announcement.
  Future<void> _notifyUpdate(String title, String body) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      // 1. Create a public announcement record
      await _fs.add('announcements', {
        'title':         '📅 $title',
        'message':       body,
        'createdAt':     Timestamp.now(),
        'createdBy':     user.uid,
        'attachmentUrl': '',
        'isPinned':      false,
        'fcmSent':       true,
      });

      // 2. Broadcast via FCM (Free Topic Messaging)
      final idToken   = await AuthService.instance.getIdToken(forceRefresh: true);
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
      
      var notificationBody = body;
      // Note: we don't have the slot object here easily, but we can 
      // improve the body before calling _notifyUpdate in addSlot/editSlot 
      // instead. I'll just keep it as is or improve the callers.
      
      if (idToken != null && projectId.isNotEmpty) {
        final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
        await _dio.post(
          url,
          options: Options(headers: {'Authorization': 'Bearer $idToken'}),
          data: {
            'message': {
              'topic': 'class_announcements', // Every app is subscribed to this topic
              'notification': {
                'title': '📅 $title',
                'body':  body,
              },
              'android': {
                'notification': {'channel_id': 'classmate_channel'},
              },
            },
          },
        ).then((res) => debugPrint('[FCM] Timetable broadcast sent: ${res.statusCode}'))
         .catchError((e) => debugPrint('[FCM] Timetable broadcast failed: $e'));
      }
    } catch (e) {
      debugPrint('[Timetable] Notification failed (non-fatal): $e');
    }
  }

  Future<void> syncNewTimetable() async {
    final Map<String, List<Map<String, dynamic>>> newTimetable = {
      'Monday': [
        { "startTime": "13:30", "endTime": "14:30", "subject": "OOP", "teacher": "SMS", "room": "MC312", "section": "A", "type": "lecture" },
        { "startTime": "13:30", "endTime": "14:30", "subject": "LA", "teacher": "PAB", "room": "MB607", "section": "B", "type": "lecture" },
        { "startTime": "14:30", "endTime": "16:30", "subject": "LA", "teacher": "PAB", "room": "MB607", "section": "A", "type": "lecture" },
        { "startTime": "14:30", "endTime": "16:30", "subject": "PE", "teacher": "ART", "room": "MC317", "section": "B", "type": "lecture" },
        { "startTime": "16:30", "endTime": "17:00", "subject": "BREAK", "teacher": "", "room": "", "section": "", "type": "break" },
        { "startTime": "17:00", "endTime": "18:30", "subject": "3D", "teacher": "SKJ", "room": "MA513", "section": "A", "type": "lab" },
        { "startTime": "17:00", "endTime": "18:30", "subject": "3D", "teacher": "BMV", "room": "MA513", "section": "B", "type": "lab" }
      ],
      'Tuesday': [
        { "startTime": "13:30", "endTime": "15:00", "subject": "PC", "teacher": "DV", "room": "MB507", "section": "", "type": "lecture" },
        { "startTime": "15:00", "endTime": "16:20", "subject": "3D", "teacher": "BMV", "room": "MA513", "section": "A", "type": "lab" },
        { "startTime": "15:00", "endTime": "16:20", "subject": "3D", "teacher": "SBB", "room": "MA513", "section": "B", "type": "lab" },
        { "startTime": "16:20", "endTime": "17:00", "subject": "BREAK", "teacher": "", "room": "", "section": "", "type": "break" },
        { "startTime": "17:00", "endTime": "18:30", "subject": "LA", "teacher": "PAB", "room": "MA206", "section": "", "type": "lecture" }
      ],
      'Wednesday': [
        { "startTime": "13:30", "endTime": "14:30", "subject": "DMS", "teacher": "TNB", "room": "MB310", "section": "", "type": "lecture" },
        { "startTime": "14:30", "endTime": "16:30", "subject": "OOP", "teacher": "SMS", "room": "MA306A", "section": "A", "type": "lab" },
        { "startTime": "14:30", "endTime": "16:30", "subject": "DMS", "teacher": "TNB", "room": "MA308", "section": "B", "type": "lab" },
        { "startTime": "16:30", "endTime": "17:00", "subject": "BREAK", "teacher": "", "room": "", "section": "", "type": "break" },
        { "startTime": "17:00", "endTime": "18:00", "subject": "OOP", "teacher": "CPC", "room": "MA206", "section": "", "type": "lecture" },
        { "startTime": "18:00", "endTime": "18:30", "subject": "LIBRARY", "teacher": "", "room": "", "section": "", "type": "lecture" }
      ],
      'Thursday': [
        { "startTime": "13:30", "endTime": "14:30", "subject": "DMS", "teacher": "TNB", "room": "MB205A", "section": "A", "type": "lecture" },
        { "startTime": "13:30", "endTime": "14:30", "subject": "OOP", "teacher": "SMS", "room": "MB010", "section": "B", "type": "lecture" },
        { "startTime": "14:30", "endTime": "16:30", "subject": "DMS", "teacher": "TNB", "room": "MA305", "section": "", "type": "lab" },
        { "startTime": "16:30", "endTime": "17:00", "subject": "BREAK", "teacher": "", "room": "", "section": "", "type": "break" },
        { "startTime": "17:00", "endTime": "18:30", "subject": "LA", "teacher": "PAB", "room": "MA206", "section": "", "type": "lecture" }
      ],
      'Friday': [
        { "startTime": "09:00", "endTime": "10:30", "subject": "BES", "teacher": "AK", "room": "Online", "section": "", "type": "lecture" },
        { "startTime": "13:30", "endTime": "14:30", "subject": "PE1-DS", "teacher": "PG3SHA", "room": "PG3SHA", "section": "", "type": "lecture" },
        { "startTime": "14:30", "endTime": "15:30", "subject": "OOP", "teacher": "CPC", "room": "MB607", "section": "", "type": "lecture" },
        { "startTime": "15:30", "endTime": "16:30", "subject": "VA2", "teacher": "DT", "room": "MB607", "section": "", "type": "lecture" },
        { "startTime": "16:30", "endTime": "17:00", "subject": "BREAK", "teacher": "", "room": "", "section": "", "type": "break" },
        { "startTime": "17:00", "endTime": "18:30", "subject": "PE", "teacher": "ART", "room": "MA209", "section": "A", "type": "lecture" },
        { "startTime": "17:00", "endTime": "18:30", "subject": "OOP", "teacher": "SMS", "room": "MA207", "section": "B", "type": "lecture" }
      ],
      'Saturday': []
    };

    for (var entry in newTimetable.entries) {
      await _fs.set('timetable/${entry.key}', {
        'day': entry.key,
        'slots': entry.value,
      });
    }
    debugPrint('[Timetable] Sync complete.');
  }
}

final timetableControllerProvider =
    StateNotifierProvider.autoDispose<TimetableController, TimetableCrudState>(
  (_) => TimetableController(),
);
