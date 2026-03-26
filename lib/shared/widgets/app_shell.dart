import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../widgets/offline_banner.dart';
import '../../features/timetable/controllers/timetable_controller.dart';
import '../../features/timetable/screens/timetable_screen.dart';
import '../../features/mcq/providers/mcq_feature_provider.dart';

/// Main app shell — wraps all bottom-nav routes.
/// Passed as the [builder] of go_router's ShellRoute.
class AppShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  // ── Static tab config ─────────────────────────────────
  static const _staticTabs = [
    _TabItem(route: '/home/dashboard',     icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,          label: 'Home'),
    _TabItem(route: '/home/tasks',         icon: Icons.task_alt_outlined,       activeIcon: Icons.task_alt_rounded,      label: 'Tasks'),
    _TabItem(route: '/home/timetable',     icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded,label: 'Timetable'),
    _TabItem(route: '/home/materials',     icon: Icons.folder_outlined,         activeIcon: Icons.folder_rounded,        label: 'Materials'),
    _TabItem(route: '/home/profile',       icon: Icons.person_outline,          activeIcon: Icons.person_rounded,        label: 'Profile'),
  ];

  // Pre-built tab lists — avoids allocating a new List on every build
  static final _tabsWithMcq = const [
    _TabItem(route: '/home/dashboard',     icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,          label: 'Home'),
    _TabItem(route: '/home/tasks',         icon: Icons.task_alt_outlined,       activeIcon: Icons.task_alt_rounded,      label: 'Tasks'),
    _TabItem(route: '/home/timetable',     icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded,label: 'Timetable'),
    _TabItem(route: '/home/mcq',           icon: Icons.psychology_outlined,     activeIcon: Icons.psychology_rounded,    label: 'Quiz'),
    _TabItem(route: '/home/materials',     icon: Icons.folder_outlined,         activeIcon: Icons.folder_rounded,        label: 'Materials'),
    _TabItem(route: '/home/profile',       icon: Icons.person_outline,          activeIcon: Icons.person_rounded,        label: 'Profile'),
  ];

  List<_TabItem> _getTabs(bool mcqEnabled) =>
      mcqEnabled ? _tabsWithMcq : _staticTabs;

  int _getSelectedIndex(List<_TabItem> tabs) {
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    // select() prevents full shell rebuild — only rebuilds when admin status flips
    final isAdmin     = ref.watch(isAdminProvider.select((v) => v));
    final mcqEnabled  = ref.watch(mcqFeatureEnabledProvider);
    final tabs        = _getTabs(mcqEnabled);
    final selIndex    = _getSelectedIndex(tabs);

    // Core listener to keep native repeating notifications perfectly synced with Firestore
    ref.listen(timetableStreamProvider, (_, next) {
      final map = next.valueOrNull;
      if (map != null) _syncTimetableNotifications(map);
    });

    return Scaffold(
      body: Column(
        children: [
          // Offline banner at the very top
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset:     const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppSizes.bottomNavHeight,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab      = tabs[i];
                final selected = i == selIndex;
                return Expanded(
                  child: _NavItem(
                    tab:      tab,
                    selected: selected,
                    isDark:   isDark,
                    onTap:    () => context.go(tab.route),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      // Context-sensitive FAB based on current route
      floatingActionButton: _buildFab(context, location, isAdmin),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFab(BuildContext context, String loc, bool isAdmin) {
    if (loc.startsWith('/home/tasks')) {
      return FloatingActionButton(
        heroTag:  'fab_tasks',
        onPressed: () => context.push('/home/tasks/add'),
        child: const Icon(Icons.add_rounded, size: 28),
      );
    }
    if (loc.startsWith('/home/materials') && isAdmin) {
      return FloatingActionButton(
        heroTag:  'fab_materials',
        onPressed: () => context.push('/home/materials/add'),
        child: const Icon(Icons.upload_rounded, size: 28),
      );
    }
    if (loc.startsWith('/home/announcements') && isAdmin) {
      return FloatingActionButton(
        heroTag:  'fab_announce',
        onPressed: () => context.push('/home/announcements/add'),
        child: const Icon(Icons.campaign_rounded, size: 28),
      );
    }
    if (loc.startsWith('/home/timetable') && isAdmin) {
      return FloatingActionButton(
        heroTag:  'fab_timetable',
        onPressed: () {
          // Open the sheet (we need to import TimetableScreen or similar)
          _showGlobalAddSlotSheet(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      );
    }
    return null;
  }

  void _showGlobalAddSlotSheet(BuildContext context) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // We'll need the import for AddEditSlotSheet
      builder: (_) => const AddEditSlotSheet(day: 'Monday'), 
    );
  }

  void _syncTimetableNotifications(Map<String, dynamic> timetableMap) {
    final ntf = NotificationService.instance;
    // Map of days to integer (1=Mon..7=Sun) for tz.TZDateTime weekday logic
    final dayInts = {
      'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
      'Thursday': 4, 'Friday': 5, 'Saturday': 6
    };

    dayInts.forEach((dayStr, dayInt) {
      final dayModel = timetableMap[dayStr];
      if (dayModel == null) return;
      
      final slots = dayModel.slots;
      for (int i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final id = 20000 + (dayInt * 100) + i; // Unique determinative ID for alarm
        
        // Parse "HH:MM", calculate 15 mins before
        final parts = slot.startTime.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final alarmTime = DateTime(2000, 1, 1, h, m).subtract(const Duration(minutes: 15));
        
        ntf.scheduleWeeklyNotification(
          id: id,
          title: 'Class Starting Soon',
          body: '${slot.subject} in ${slot.room} starts in 15 minutes!',
          dayOfWeek: dayInt,
          hour: alarmTime.hour,
          minute: alarmTime.minute,
        );
      }
    });
  }
}

// ── _NavItem ──────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _TabItem  tab;
  final bool      selected;
  final bool      isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor   = isDark ? AppColors.accent : AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve:    Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize:      MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve:    Curves.easeOutCubic,
              width:    selected ? 40 : 0,
              height:   3,
              decoration: BoxDecoration(
                color:        activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              selected ? tab.activeIcon : tab.icon,
              color: selected ? activeColor : inactiveColor,
              size:  AppSizes.iconMd,
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                color:      selected ? activeColor : inactiveColor,
                fontSize:   10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab config model ──────────────────────────────────────────

class _TabItem {
  final String   route;
  final IconData icon;
  final IconData activeIcon;
  final String   label;

  const _TabItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
