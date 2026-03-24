import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../materials/controllers/material_controller.dart';
import '../../../shared/models/material_model.dart';

class HomeMaterialsPreview extends ConsumerWidget {
  const HomeMaterialsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(allMaterialsProvider);
    final isDark         = context.isDark;

    return materialsAsync.when(
      loading: () => _LoadingPlaceholder(isDark: isDark),
      error:   (_, __) => const SizedBox.shrink(),
      data: (materials) {
        if (materials.isEmpty) {
          return _EmptyState(isDark: isDark);
        }

        // Show only the 3 most recent
        final recent = materials.take(3).toList();

        return Column(
          children: recent.map((m) => _MaterialHomeTile(
            material: m,
            isDark:   isDark,
          )).toList(),
        );
      },
    );
  }
}

class _MaterialHomeTile extends StatelessWidget {
  final MaterialModel material;
  final bool          isDark;

  const _MaterialHomeTile({required this.material, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final color = _getColor();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: ListTile(
        onTap: () => _openMaterial(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 4),
        leading: Container(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          material.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${material.subject} • ${_formatDate(material.uploadedAt)}',
          style: context.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
        trailing: Icon(
          material.isLink ? Icons.open_in_new_rounded : Icons.download_rounded,
          size:  18,
          color: Colors.grey,
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (material.isLink) return Icons.link_rounded;
    return switch (material.fileType) {
      'pdf'   => Icons.picture_as_pdf_rounded,
      'image' => Icons.image_rounded,
      'doc'   => Icons.description_rounded,
      _       => Icons.insert_drive_file_rounded,
    };
  }

  Color _getColor() {
    if (material.isLink) return AppColors.info;
    return switch (material.fileType) {
      'pdf'   => AppColors.error,
      'image' => AppColors.success,
      'doc'   => AppColors.primary,
      _       => Colors.grey,
    };
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }

  Future<void> _openMaterial(BuildContext context) async {
    final uri = Uri.parse(material.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open material')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: AppSizes.sm),
            Text(
              'No study materials yet',
              style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
}

class _LoadingPlaceholder extends StatelessWidget {
  final bool isDark;
  const _LoadingPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(2, (i) => Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
    )),
  );
}
