import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

// ── BuildContext Extensions ───────────────────────────────────

extension BuildContextX on BuildContext {
  ThemeData  get theme      => Theme.of(this);
  bool       get isDark     => theme.brightness == Brightness.dark;
  ColorScheme get colors    => theme.colorScheme;
  TextTheme  get textTheme  => theme.textTheme;
  Size       get screenSize => MediaQuery.of(this).size;
  double     get screenW    => screenSize.width;
  double     get screenH    => screenSize.height;

  void showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  void showSuccess(String msg) => showSnack(msg);
  void showError(String msg)   => showSnack(msg, isError: true);
}

// ── String Extensions ─────────────────────────────────────────

extension StringX on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  bool endsWithAny(List<String> suffixes) =>
      suffixes.any((s) => endsWith(s));

  /// Truncate string to [max] chars, appending '…' if truncated.
  String truncate(int max) =>
      length <= max ? this : '${substring(0, max)}…';
}

// ── DateTime Extensions ───────────────────────────────────────

extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isPast    => isBefore(DateTime.now());
  bool get isFuture  => isAfter(DateTime.now());
  bool get isOverdue => isPast;

  String get formattedDate => DateFormat('dd MMM yyyy').format(this);
  String get formattedTime => DateFormat('hh:mm a').format(this);
  String get formattedDateTime => DateFormat('dd MMM yyyy • hh:mm a').format(this);
  String get dayMonth => DateFormat('dd MMM').format(this);
  String get dayName  => DateFormat('EEEE').format(this);
  String get shortDay => DateFormat('EEE').format(this);

  String get relative {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return formattedDate;
  }

  /// Days remaining from now (0 if in the past).
  int get daysFromNow {
    final diff = difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }
}

// ── Color Extensions ──────────────────────────────────────────

extension ColorX on Color {
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

// ── Widget Extensions ─────────────────────────────────────────

extension WidgetX on Widget {
  Widget padAll(double v)   => Padding(padding: EdgeInsets.all(v), child: this);
  Widget padH(double v)     => Padding(
      padding: EdgeInsets.symmetric(horizontal: v), child: this);
  Widget padV(double v)     => Padding(
      padding: EdgeInsets.symmetric(vertical: v), child: this);
  Widget padOnly({
    double top    = 0,
    double bottom = 0,
    double left   = 0,
    double right  = 0,
  }) =>
      Padding(
        padding: EdgeInsets.fromLTRB(left, top, right, bottom),
        child: this,
      );
  Widget get expanded => Expanded(child: this);
  Widget get center   => Center(child: this);
}

// ── SizedBox shortcuts ────────────────────────────────────────
extension SizedBoxX on double {
  SizedBox get hGap => SizedBox(height: this);
  SizedBox get wGap => SizedBox(width:  this);
}

const kGapXS = SizedBox(height: AppSizes.xs);
const kGapSM = SizedBox(height: AppSizes.sm);
const kGapMD = SizedBox(height: AppSizes.md);
const kGapLG = SizedBox(height: AppSizes.lg);
const kGapXL = SizedBox(height: AppSizes.xl);
