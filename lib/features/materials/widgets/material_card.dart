import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/material_model.dart';

/// File/Link type icon + colour helper.
Color materialTypeColor(String type) => switch (type) {
  'pdf'   => const Color(0xFFE53935), // Red for PDF
  'image' => AppColors.success,
  'doc'   => const Color(0xFF1565C0), // Blue for docs
  'link'  => AppColors.accent,
  _       => AppColors.textSecondaryLight,
};

IconData materialTypeIcon(String type) => switch (type) {
  'pdf'   => Icons.picture_as_pdf_rounded,
  'image' => Icons.image_outlined,
  'doc'   => Icons.description_outlined,
  'link'  => Icons.link_rounded,
  _       => Icons.insert_drive_file_outlined,
};

/// Full-featured material card with download/open action and admin delete.
class MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final int           index;
  final bool          isAdmin;
  final VoidCallback? onDelete;

  const MaterialCard({
    super.key,
    required this.material,
    required this.index,
    this.isAdmin = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark     = context.isDark;
    final m          = material;
    final typeColor  = materialTypeColor(m.fileType);
    final typeIcon   = materialTypeIcon(m.fileType);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(isDark ? 0.12 : 0.03),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── File type icon ─────────────────────────────────
            Container(
              width:  52,
              height: 52,
              decoration: BoxDecoration(
                color:        typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(typeIcon, color: typeColor, size: 28),
            ),
            const SizedBox(width: AppSizes.md),

            // ── Info ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusRound),
                    ),
                    child: Text(
                      m.subject,
                      style: TextStyle(
                        color:      isDark
                            ? AppColors.accentLight
                            : AppColors.primary,
                        fontSize:   10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    m.title,
                    style: context.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (m.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      m.description.truncate(80),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // File size + date
                  Row(
                    children: [
                      if (m.fileSizeLabel.isNotEmpty) ...[
                        Text(m.fileSizeLabel,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 11,
                            )),
                        const Text(' · ',
                            style: TextStyle(color: AppColors.textSecondaryLight)),
                      ],
                      Text(m.uploadedAt.relative,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // ── Actions column ─────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Download / Open
                IconButton(
                  icon: Icon(
                    m.isLink
                        ? Icons.open_in_new_rounded
                        : Icons.download_rounded,
                    color: typeColor,
                  ),
                  tooltip:  m.isLink ? 'Open Link' : 'Download',
                  onPressed: () => _openUrl(m.url),
                  style: IconButton.styleFrom(
                    backgroundColor: typeColor.withOpacity(0.1),
                    padding:         const EdgeInsets.all(8),
                  ),
                ),
                if (isAdmin && onDelete != null) ...[
                  const SizedBox(height: 4),
                  IconButton(
                    icon:     const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 18),
                    tooltip:  'Delete',
                    onPressed: onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.08),
                      padding:         const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index))
        .slideX(begin: 0.04);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
