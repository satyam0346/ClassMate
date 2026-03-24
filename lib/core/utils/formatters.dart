import 'package:intl/intl.dart';

/// Date/time and file size formatting utilities.
abstract class AppFormatters {

  // ── Date formatting ──────────────────────────────────────────
  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy • hh:mm a').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('hh:mm a').format(date);

  static String formatDayMonth(DateTime date) =>
      DateFormat('dd MMM').format(date);

  /// Returns a relative time string like "2 hours ago" or "Just now".
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return formatDate(date);
  }

  // ── Countdown ────────────────────────────────────────────────
  /// Returns a human-readable countdown string.
  /// e.g. "3 days 4 hrs" or "2 hrs 15 min" or "45 min" or "Exam started"
  static String countdown(DateTime target) {
    final now  = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return 'Exam started';
    if (diff.inDays    >= 1) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours   >= 1) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return '< 1 min';
  }

  // ── File size ────────────────────────────────────────────────
  static String fileSize(int bytes) {
    if (bytes < 1024)              return '${bytes}B';
    if (bytes < 1024 * 1024)       return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // ── Priority label ───────────────────────────────────────────
  static String priorityLabel(String priority) {
    switch (priority) {
      case 'high':   return '🔴 High';
      case 'medium': return '🟡 Medium';
      case 'low':    return '🟢 Low';
      default:       return priority;
    }
  }

  // ── Status label ─────────────────────────────────────────────
  static String statusLabel(String status) {
    switch (status) {
      case 'pending':     return 'Pending';
      case 'in_progress': return 'In Progress';
      case 'done':        return 'Done';
      default:            return status;
    }
  }
}
