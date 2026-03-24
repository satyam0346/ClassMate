import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Non-dismissible OTA update dialog.
/// Shown when Remote Config force_update == true and local version is behind.
/// The WillPopScope prevents back-button dismissal.
class OtaUpdateDialog extends ConsumerWidget {
  final String message;
  final String downloadUrl;

  const OtaUpdateDialog({
    super.key,
    required this.message,
    required this.downloadUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveMessage = message.isNotEmpty
        ? message
        : 'A new version of ClassMate is available with improvements and '
          'bug fixes. Please update to continue.';

    return WillPopScope(
      onWillPop: () async => false, // Non-dismissible
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.lg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Update icon with glow
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.primary,
                size:  40,
              ),
            )
                .animate()
                .scale(curve: Curves.easeOutBack, duration: 400.ms)
                .then()
                .shake(duration: 300.ms, hz: 2, offset: const Offset(0, -4)),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'Update Required',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              effectiveMessage,
              style: TextStyle(
                color:   Colors.grey[600],
                fontSize: 14,
                height:  1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            SizedBox(
              width:  double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: downloadUrl.isNotEmpty
                    ? () => _openDownloadUrl(context)
                    : null,
                icon:  const Icon(Icons.download_rounded),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDownloadUrl(BuildContext context) async {
    if (downloadUrl.isEmpty) return;
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open download link. Contact admin.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
