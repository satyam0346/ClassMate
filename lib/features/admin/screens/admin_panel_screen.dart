import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: isDark ? AppColors.cardDark : AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: AppSizes.md, bottom: AppSizes.md),
              title: const Text(
                '👑 Admin Panel',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AdminActionCard(
                  title: 'Post Announcement',
                  subtitle: 'Send FCM notification to all students',
                  icon: Icons.campaign_rounded,
                  color: AppColors.accent,
                  onTap: () => context.push('/home/announcements/add'),
                ),
                const SizedBox(height: AppSizes.md),
                _AdminActionCard(
                  title: 'Upload Material',
                  subtitle: 'Share PDF, DOCs, or Links',
                  icon: Icons.upload_file_rounded,
                  color: AppColors.info,
                  onTap: () => context.push('/home/materials/add'),
                ),
                const SizedBox(height: AppSizes.md),
                _AdminActionCard(
                  title: 'Add New Exam',
                  subtitle: 'Schedule upcoming official exams',
                  icon: Icons.event_note_rounded,
                  color: AppColors.warning,
                  onTap: () => context.push('/home/exams/add'),
                ),
                const SizedBox(height: AppSizes.md),
                _AdminActionCard(
                  title: 'Class Timetable',
                  subtitle: 'Update weekly schedule slots',
                  icon: Icons.view_timeline_rounded,
                  color: AppColors.success,
                  onTap: () => context.push('/home/timetable'), // Redirects to Timetable
                ),
                const SizedBox(height: AppSizes.xl),
                const Divider(),
                const SizedBox(height: AppSizes.md),
                Text(
                  'User Management',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.md),
                _AdminActionCard(
                  title: 'View All Students',
                  subtitle: 'See registered users & profiles',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primaryLight,
                  onTap: () => context.push('/home/admin/students'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.12 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}
