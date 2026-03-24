import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Generic empty state widget with icon, title, message, and optional action.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String?  message;
  final String?  actionLabel;
  final VoidCallback? onAction;
  final Color?   iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ??
        (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated icon
            Container(
              width:  96,
              height: 96,
              decoration: BoxDecoration(
                color:        effectiveIconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: Icon(icon, size: 48, color: effectiveIconColor),
            )
                .animate()
                .scale(curve: Curves.easeOutBack, duration: 400.ms)
                .fadeIn(),
            const SizedBox(height: AppSizes.lg),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            if (message != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon:  const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Specialised variants ──────────────────────────────────────

class NoTasksEmpty extends StatelessWidget {
  final VoidCallback? onAdd;
  const NoTasksEmpty({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) => EmptyStateWidget(
        icon:        Icons.task_alt_rounded,
        title:       'No Tasks Yet',
        message:     'Add a task to get started.',
        actionLabel: onAdd != null ? '+ Add Task' : null,
        onAction:    onAdd,
        iconColor:   AppColors.priorityMedium,
      );
}

class NoMaterialsEmpty extends StatelessWidget {
  final VoidCallback? onAdd;
  const NoMaterialsEmpty({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) => EmptyStateWidget(
        icon:        Icons.folder_open_outlined,
        title:       'No Materials Yet',
        message:     'Admin will upload study materials here.',
        actionLabel: onAdd != null ? '+ Upload' : null,
        onAction:    onAdd,
        iconColor:   AppColors.info,
      );
}

class NoAnnouncementsEmpty extends StatelessWidget {
  const NoAnnouncementsEmpty({super.key});

  @override
  Widget build(BuildContext context) => const EmptyStateWidget(
        icon:     Icons.campaign_outlined,
        title:    'No Announcements',
        message:  'Admin announcements will show here.',
        iconColor: AppColors.accent,
      );
}

class OfflineEmpty extends StatelessWidget {
  const OfflineEmpty({super.key});

  @override
  Widget build(BuildContext context) => const EmptyStateWidget(
        icon:    Icons.wifi_off_rounded,
        title:   'You\'re Offline',
        message: 'Check your internet connection. '
            'Cached data is shown where available.',
        iconColor: AppColors.warning,
      );
}

class ErrorStateWidget extends StatelessWidget {
  final String?      message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyStateWidget(
        icon:        Icons.error_outline_rounded,
        title:       'Something went wrong',
        message:     message ?? 'An unexpected error occurred.',
        actionLabel: onRetry != null ? 'Try Again' : null,
        onAction:    onRetry,
        iconColor:   AppColors.error,
      );
}
