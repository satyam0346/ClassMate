import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/timetable_model.dart';

/// A premium timeline-inspired slot card matching the 'Modern Classes' design.
class SlotCard extends StatelessWidget {
  final SlotModel    slot;
  final int          index;
  final bool         isAdmin;
  final bool         isLast;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SlotCard({
    super.key,
    required this.slot,
    required this.index,
    this.isAdmin  = false,
    this.isLast   = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = context.isDark;
    final typeColor = _typeColor(slot.type);
    final isActive  = slot.isCurrentlyActive;
    final isOver    = slot.isOver;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: Time ─────────────────────────────────────
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatDisplay(slot.startTime),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSizes.md),

          // ── Centre: Timeline Indicator ──────────────────────
          Column(
            children: [
              // Indicator dot
              Container(
                width:  isActive ? 20 : 12,
                height: isActive ? 20 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.transparent : Colors.transparent,
                  border: Border.all(
                    color: isActive ? AppColors.success : (isDark ? Colors.white24 : Colors.black12),
                    width: isActive ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width:  isActive ? 8 : 0,
                    height: isActive ? 8 : 0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
              // Connecting line
              if (!isLast)
                Expanded(
                  child: Container(
                    width:  1.5,
                    color: isDark ? Colors.white12 : Colors.black12,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),

          const SizedBox(width: AppSizes.md),

          // ── Right: Content ──────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24), // Spacing between cards
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slot.subject,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Now',
                            style: TextStyle(
                              color:      AppColors.success,
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (slot.room.isNotEmpty)
                    _MetaRow(
                      icon:  Icons.room_outlined,
                      label: 'Room ${slot.room}',
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                  const SizedBox(height: 4),
                  if (slot.teacher.isNotEmpty)
                    _MetaRow(
                      icon:  Icons.person_outline,
                      label: slot.teacher,
                      color: Colors.blueAccent,
                      isDark: isDark,
                    ),
                  
                  // Admin actions (only visible in admin mode)
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _SmallAction(icon: Icons.edit_outlined, color: AppColors.info, onTap: onEdit),
                        const SizedBox(width: AppSizes.sm),
                        _SmallAction(icon: Icons.delete_outline, color: AppColors.error, onTap: onDelete),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1);
  }

  String _formatDisplay(String t) {
    try {
      final parts  = t.split(':');
      var   hour   = int.parse(parts[0]);
      final minute = parts[1];
      final amPm   = hour >= 12 ? 'AM' : 'AM'; // Match design preference if needed, but keeping real
      final realAmPm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $realAmPm';
    } catch (_) {
      return t;
    }
  }

  Color _typeColor(String type) => switch (type) {
    'lab'      => AppColors.success,
    'tutorial' => AppColors.warning,
    'break'    => AppColors.textSecondaryLight,
    _          => AppColors.primary,
  };
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     isDark;

  const _MetaRow({required this.icon, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
}

class _SmallAction extends StatelessWidget {
  final IconData      icon;
  final Color         color;
  final VoidCallback? onTap;

  const _SmallAction({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}
