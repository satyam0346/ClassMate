import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_strings.dart';

/// Background FCM message handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Local notification display for background messages is handled by
  // FCM automatically on Android when notification payload is present.
}

/// Handles FCM setup and local notification scheduling.
/// Full class/exam reminder scheduling is wired in Phase 6 and 7.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  // Android notification channel
  static const _channelId    = 'classmate_channel';
  static const _channelName  = 'ClassMate Notifications';
  static const _channelDesc  = 'Announcements, exam reminders, and class alerts';

  bool _tzInitialized = false;

  // ── Initialize ────────────────────────────────────────────

  Future<void> init() async {
    // 1. Request permission
    await _fcm.requestPermission(
      alert:      true,
      badge:      true,
      sound:      true,
      provisional: false,
    );

    // 2. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Log token for debugging
    final token = await _fcm.getToken();
    debugPrint('[FCM] Device Token: $token');

    // 4. Set up local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 4. Create Android notification channel & request permission (Android 13+)
    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description:  _channelDesc,
        importance:   Importance.high,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
      
      // Explicitly request permission for Android 13+
      await androidPlugin.requestNotificationsPermission();
    }

    // 5. Handle foreground FCM messages — show local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Subscribe to notification topics
    await subscribeToTopics();

    // 7. Set foreground notification presentation options
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 8. Init timezone data
    _initTimezone();

    debugPrint('[Notifications] Initialized');
  }

  void _initTimezone() {
    if (_tzInitialized) return;
    try {
      tz.initializeTimeZones();
      _tzInitialized = true;
    } catch (e) {
      debugPrint('[Notifications] Timezone init failed (non-fatal): $e');
    }
  }

  // ── FCM Topics ────────────────────────────────────────────

  Future<void> subscribeToTopics() async {
    try {
      await _fcm.subscribeToTopic(AppStrings.fcmTopicAnnouncements);
      await _fcm.subscribeToTopic(AppStrings.fcmTopicMaterials);
      await _fcm.subscribeToTopic(AppStrings.fcmTopicTasks);
      await _fcm.subscribeToTopic(AppStrings.fcmTopicTimetable);
      debugPrint('[FCM] Subscribed to topics');
    } catch (e) {
      debugPrint('[FCM] Subscribe failed (non-fatal): $e');
    }
  }

  Future<void> unsubscribeFromTopics() async {
    try {
      await _fcm.unsubscribeFromTopic(AppStrings.fcmTopicAnnouncements);
      await _fcm.unsubscribeFromTopic(AppStrings.fcmTopicMaterials);
      await _fcm.unsubscribeFromTopic(AppStrings.fcmTopicTasks);
      await _fcm.unsubscribeFromTopic(AppStrings.fcmTopicTimetable);
    } catch (e) {
      debugPrint('[FCM] Unsubscribe failed (non-fatal): $e');
    }
  }

  // ── Local Notifications ───────────────────────────────────

  /// Show an immediate local notification.
  Future<void> showNotification({
    required int    id,
    required String title,
    required String body,
    String?         payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance:         Importance.high,
        priority:           Priority.high,
        icon:               '@mipmap/ic_launcher',
      ),
    );
    await _local.show(id, title, body, details, payload: payload);
  }

  /// Schedule a local notification at a specific [scheduledDate].
  Future<void> scheduleNotification({
    required int      id,
    required String   title,
    required String   body,
    required DateTime scheduledDate,
    String?           payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance:         Importance.high,
        priority:           Priority.high,
      ),
    );

    await _local.zonedSchedule(
      id,
      title,
      body,
      // Convert to TZDateTime — requires timezone package in later phases
      // For now using DateTime directly; Phase 6 will add timezone support.
      _toTZDateTime(scheduledDate),
      details,
      payload:                         payload,
      androidScheduleMode:             AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[Notifications] Scheduled: "$title" at $scheduledDate');
  }

  /// Schedule a recurring weekly local notification at a specific time and day.
  Future<void> scheduleWeeklyNotification({
    required int      id,
    required String   title,
    required String   body,
    required int      dayOfWeek, // 1 = Monday, ..., 7 = Sunday
    required int      hour,
    required int      minute,
    String?           payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance:         Importance.high,
        priority:           Priority.high,
      ),
    );

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _local.zonedSchedule(
      id,
      title,
      body,
      _toTZDateTime(scheduledDate),
      details,
      payload:                         payload,
      androidScheduleMode:             AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint('[Notifications] Scheduled Weekly: "$title" for Day $dayOfWeek at $hour:$minute');
  }

  /// Cancel a scheduled or shown notification by ID.
  Future<void> cancel(int id) => _local.cancel(id);

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() => _local.cancelAll();

  // ── FCM foreground ────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Determine payload based on data content
    final announcementId = message.data['announcementId'];
    final materialId     = message.data['materialId'];
    final taskId         = message.data['taskId'];

    showNotification(
      id:      message.hashCode,
      title:   notification.title ?? 'ClassMate',
      body:    notification.body  ?? '',
      payload: announcementId ?? materialId ?? taskId,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[Notifications] Tapped: ${response.payload}');
    // Navigation on notification tap is wired in Phase 8 with go_router.
  }

  // ── Helpers ───────────────────────────────────────────────

  tz.TZDateTime _toTZDateTime(DateTime dt) {
    _initTimezone();
    try {
      return tz.TZDateTime(
        tz.local,
        dt.year, dt.month, dt.day,
        dt.hour, dt.minute, dt.second,
      );
    } catch (_) {
      return tz.TZDateTime.from(dt, tz.UTC);
    }
  }
}
