import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/announcement_model.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../controllers/announcement_controller.dart';

/// Card for a single announcement in the list.
class AnnouncementCard extends ConsumerWidget {
  final AnnouncementModel announcement;
  final int               index;
  final bool              isAdmin;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.index,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = context.isDark;
    final a           = announcement;
    final lastRead    = ref.watch(lastReadAnnouncementsProvider);
    final isUnread    = a.createdAt.isAfter(lastRead);

    return GestureDetector(
      onTap: () => context.push('/home/announcements/${a.id}', extra: a),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSizes.xs),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: a.isPinned
                ? AppColors.accent.withOpacity(0.4)
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: a.isPinned ? 1.5 : 1,
          ),
          boxShadow: a.isPinned
              ? [
                  BoxShadow(
                    color:      AppColors.accent.withOpacity(0.1),
                    blurRadius: 12,
                    offset:     const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color:      Colors.black.withOpacity(isDark ? 0.12 : 0.03),
                    blurRadius: 6,
                    offset:     const Offset(0, 2),
                  )
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon avatar with potential unread dot indicator
                  Stack(
                    children: [
                      Container(
                        width:  44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: a.isPinned
                                ? [AppColors.accent.withOpacity(0.8), AppColors.primary]
                                : [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end:   Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: Colors.white, size: 22),
                      ),
                      if (isUnread)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSizes.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pin badge + timestamp
                        Row(
                          children: [
                            if (a.isPinned) ...[
                              _PinBadge(),
                              const SizedBox(width: AppSizes.sm),
                            ],
                            Expanded(
                              child: Text(
                                a.createdAt.relative,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            if (a.fcmSent)
                              const Icon(Icons.send_rounded,
                                  size: 12, color: AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.title,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Preview message ────────────────────────────────
              Text(
                a.message.truncate(150),
                style: context.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),

              if (a.hasAttachment) ...[
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(Icons.attach_file_rounded,
                        size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text('Attachment',
                        style: TextStyle(
                          fontSize: 11,
                          color:    AppColors.info,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ],

              // ── Admin actions ──────────────────────────────────
              if (isAdmin) ...[
                const SizedBox(height: AppSizes.xs),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Pin toggle
                    TextButton.icon(
                      onPressed: () => ref
                          .read(announcementControllerProvider.notifier)
                          .togglePin(a.id, a.isPinned),
                      icon: Icon(
                        a.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        a.isPinned ? 'Unpin' : 'Pin',
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(
                          '/home/announcements/edit/${a.id}', extra: a),
                      icon: const Icon(Icons.edit_outlined,
                          size: 14, color: AppColors.info),
                      label: const Text('Edit',
                          style:
                              TextStyle(color: AppColors.info, fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, ref, a),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 14, color: AppColors.error),
                      label: const Text('Delete',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 50 * index))
          .slideY(begin: 0.05),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AnnouncementModel a) async {
    final ok = await showConfirmationDialog(
      context:       context,
      title:         'Delete Announcement',
      message:       'Remove "${a.title}"? This cannot be undone.',
      confirmLabel:  'Delete',
      isDestructive: true,
    );
    if (ok) {
      ref
          .read(announcementControllerProvider.notifier)
          .deleteAnnouncement(a.id);
    }
  }
}

// ── Pin badge ─────────────────────────────────────────────────

class _PinBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:        AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          border:
              Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.push_pin, size: 9, color: AppColors.accent),
            SizedBox(width: 3),
            Text('Pinned',
                style: TextStyle(
                  fontSize:   9,
                  color:      AppColors.accent,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
}
