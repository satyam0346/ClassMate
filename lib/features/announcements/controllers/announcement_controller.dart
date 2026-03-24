import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../shared/models/announcement_model.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/fcm_server_service.dart';

// ── Unread Badge Tracking ─────────────────────────────────────

const _kLastReadAnnouncementsKey = 'classmate_last_read_announcements';

final lastReadAnnouncementsProvider = StateNotifierProvider<LastReadNotifier, DateTime>((ref) {
  return LastReadNotifier();
});

class LastReadNotifier extends StateNotifier<DateTime> {
  LastReadNotifier() : super(DateTime.fromMillisecondsSinceEpoch(0)) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastReadAnnouncementsKey) ?? 0;
    state = DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    state = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastReadAnnouncementsKey, now.millisecondsSinceEpoch);
  }
}

// ── Stream providers ──────────────────────────────────────────

/// All announcements: pinned first, then most recent.
final announcementsProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  // Fetch everything and sort in memory to avoid needing a Firestore composite index.
  // This is better for a classroom app where the number of announcements is small.
  return FirebaseFirestore.instance
      .collection('announcements')
      .snapshots()
      .map((s) {
        final list = s.docs.map(AnnouncementModel.fromFirestore).toList();
        list.sort((a, b) {
          // 1. Pinned first
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          // 2. Then most recent createdAt
          return b.createdAt.compareTo(a.createdAt);
        });
        return list;
      });
});

/// Latest 3 announcements — for home dashboard widget.
final latestAnnouncementsProvider =
    Provider<List<AnnouncementModel>>((ref) {
  final all = ref.watch(announcementsProvider).valueOrNull ?? [];
  return all.take(3).toList();
});

// ── CRUD state ────────────────────────────────────────────────

class AnnouncementCrudState {
  final bool   isSaving;
  final String? error;
  final bool   success;

  const AnnouncementCrudState({
    this.isSaving = false,
    this.error,
    this.success  = false,
  });

  AnnouncementCrudState copyWith({
    bool?   isSaving,
    String? error,
    bool?   success,
  }) =>
      AnnouncementCrudState(
        isSaving: isSaving ?? this.isSaving,
        error:    error,
        success:  success  ?? this.success,
      );

  AnnouncementCrudState reset() => const AnnouncementCrudState();
}

// ── Controller ────────────────────────────────────────────────

class AnnouncementController
    extends StateNotifier<AnnouncementCrudState> {
  AnnouncementController() : super(const AnnouncementCrudState());

  final _fs  = FirestoreService.instance;
  final _dio = Dio();

  // ── Create ────────────────────────────────────────────────

  Future<void> createAnnouncement({
    required String title,
    required String message,
    required String createdBy,
    bool   isPinned       = false,
    String attachmentUrl  = '',
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final announcement = AnnouncementModel(
        id:            '',
        title:         InputSanitizer.sanitizeTitle(title),
        message:       InputSanitizer.sanitizeDescription(message),
        createdAt:     DateTime.now(),
        createdBy:     createdBy,
        attachmentUrl: attachmentUrl,
        isPinned:      isPinned,
        fcmSent:       false,
      );

      final ref = await _fs.add('announcements', announcement.toFirestore());

      // Send FCM directly from client using bundled Service Account (Serverless workaround)
      final fcmSent = await FcmServerService.sendNotification(
        title:   announcement.title,
        body:    _truncate(announcement.message, 100),
        topic:   AppStrings.fcmTopicAnnouncements,
        data:    {'announcementId': ref.id},
      );
      
      if (fcmSent) {
        await _fs.update('announcements/${ref.id}', {'fcmSent': true});
      }

      state = state.copyWith(isSaving: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Update ────────────────────────────────────────────────

  Future<void> updateAnnouncement(AnnouncementModel a) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _fs.update('announcements/${a.id}', {
        'title':         InputSanitizer.sanitizeTitle(a.title),
        'message':       InputSanitizer.sanitizeDescription(a.message),
        'isPinned':      a.isPinned,
        'attachmentUrl': a.attachmentUrl,
      });
      state = state.copyWith(isSaving: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Toggle pin ────────────────────────────────────────────

  Future<void> togglePin(String id, bool currentlyPinned) async {
    try {
      await _fs.update('announcements/$id', {'isPinned': !currentlyPinned});
    } catch (e) {
      debugPrint('[Announcement] togglePin failed (non-fatal): $e');
    }
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteAnnouncement(String id) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _fs.delete('announcements/$id');
      state = state.copyWith(isSaving: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Client-side FCM ───────────────────────────────────────
  // Note: Push notifications are explicitly sent from the device 
  // without a backend to accommodate Spark plan constraints.

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  void resetState() => state = state.reset();
}

final announcementControllerProvider = StateNotifierProvider.autoDispose<
    AnnouncementController, AnnouncementCrudState>(
  (_) => AnnouncementController(),
);
