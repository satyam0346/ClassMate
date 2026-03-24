import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/announcement_model.dart';

/// Full-detail view for a single announcement.
class AnnouncementDetailScreen extends ConsumerWidget {
  final AnnouncementModel announcement;
  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final a      = announcement;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ────────────────────────────────────
          SliverAppBar(
            pinned:         true,
            expandedHeight: 140,
            backgroundColor:
                isDark ? AppColors.cardDark : AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: isDark 
                      ? [AppColors.primaryDark, const Color(0xFF1E1E4D)] 
                      : [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight.withOpacity(0.85)],
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.only(
                  left: AppSizes.md, bottom: AppSizes.md),
              title: const Text('📢 Announcement',
                  style: TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   16)),
            ),
            leading: IconButton(
              icon:      const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // ── Content ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Pinned badge
                if (a.isPinned) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color:        AppColors.accent.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusRound),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12,
                              color: AppColors.accent),
                          SizedBox(width: 6),
                          Text('Pinned Announcement',
                              style: TextStyle(
                                color:      AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize:   12,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                ],

                // ── Title ──────────────────────────────────────
                Text(
                  a.title,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                const SizedBox(height: AppSizes.sm),

                // ── Meta ───────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Text(a.createdAt.formattedDateTime,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        )),
                    if (a.fcmSent) ...[
                      const SizedBox(width: AppSizes.sm),
                      const Icon(Icons.send_rounded,
                          size: 12, color: AppColors.success),
                      const SizedBox(width: 3),
                      Text('Sent to all',
                          style: TextStyle(
                            color:    AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ],
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: AppSizes.xl),
                Divider(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
                const SizedBox(height: AppSizes.lg),

                // ── Message body ───────────────────────────────
                SelectableText(
                  a.message,
                  style: context.textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                    letterSpacing: 0.1,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                // ── Attachment ─────────────────────────────────
                if (a.hasAttachment) ...[
                  const SizedBox(height: AppSizes.xl),
                  const Divider(),
                  const SizedBox(height: AppSizes.md),
                  Text('Attachment',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                  const SizedBox(height: AppSizes.sm),
                  GestureDetector(
                    onTap: () => _openUrl(a.attachmentUrl),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.cardLight,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_rounded,
                              color: AppColors.info),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Text(
                              a.attachmentUrl,
                              style: TextStyle(
                                color:       AppColors.info,
                                decoration:  TextDecoration.underline,
                                fontSize:    13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded,
                              size: 18, color: AppColors.info),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
