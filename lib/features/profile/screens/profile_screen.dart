import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_tile.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final isDark    = context.isDark;

    return Scaffold(
      body: userAsync.when(
        loading: () => const _ProfileShimmer(),
        error:   (e, _) => EmptyStateWidget(
          icon:    Icons.error_outline,
          title:   'Failed to load profile',
          message: e.toString(),
        ),
        data: (user) {
          if (user == null) {
            return EmptyStateWidget(
              icon:    Icons.person_off_outlined,
              title:   'Profile not found',
              message: 'Your profile could not be loaded.',
              actionLabel: 'Complete Profile',
              onAction:    () => context.push('/home/profile/edit'),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── Header sliver ───────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned:         true,
                    backgroundColor: AppColors.primary,
                actions: [
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.push('/home/profile/edit'),
                  ),
                  // Theme toggle
                  IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end:   Alignment.bottomRight,
                        colors: [
                          Color(0xFF0D0D3D),
                          Color(0xFF1A1A5E),
                          Color(0xFF1E1E7A),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSizes.xl),
                        const ProfileAvatar(size: AppSizes.avatarLg),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          user.name,
                          style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: AppSizes.xs),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? AppColors.accent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusRound),
                            border: Border.all(
                              color: user.isAdmin
                                  ? AppColors.accent.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            user.isAdmin ? '👑 Admin' : '🎓 Student',
                            style: TextStyle(
                              color: user.isAdmin
                                  ? AppColors.accent
                                  : Colors.white.withOpacity(0.9),
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
                            child: Text(
                              user.bio,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Info cards ──────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Wide tiles
                    ProfileInfoTileWide(
                      icon:  Icons.email_outlined,
                      label: 'EMAIL',
                      value: user.email,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: AppSizes.sm),
                    ProfileInfoTileWide(
                      icon:  Icons.phone_outlined,
                      label: 'PHONE',
                      value: user.phone,
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                    const SizedBox(height: AppSizes.md),

                    // Grid tiles (2 columns)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap:     true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSizes.sm,
                      mainAxisSpacing:  AppSizes.sm,
                      childAspectRatio: 1.8,
                      children: [
                        ProfileInfoTile(
                          icon:  Icons.class_outlined,
                          label: 'CLASS',
                          value: user.classGroup,
                        ),
                        ProfileInfoTile(
                          icon:  Icons.group_outlined,
                          label: 'SECTION',
                          value: user.section,
                        ),
                        ProfileInfoTile(
                          icon:  Icons.tag,
                          label: 'ROLL NO',
                          value: user.rollNo,
                          iconColor: AppColors.info,
                        ),
                        ProfileInfoTile(
                          icon:  Icons.badge_outlined,
                          label: 'GR NUMBER',
                          value: user.grNumber,
                          iconColor: AppColors.info,
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: AppSizes.xl),

                    // Actions
                    SizedBox(
                      width:  double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/home/profile/edit'),
                        icon:  const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      width:  double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(context, ref),
                        icon:  Icon(Icons.logout_rounded,
                            color: AppColors.error),
                        label: Text('Logout',
                            style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: AppSizes.xxl),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title:   'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      await ref.read(authControllerProvider).signOut();
    }
  }
}

// ── Profile Shimmer ───────────────────────────────────────────

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          expandedHeight: 260,
          pinned:         true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSizes.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ProfileShimmerCard(height: 72),
              SizedBox(height: AppSizes.sm),
              ProfileShimmerCard(height: 72),
              SizedBox(height: AppSizes.md),
              GridView.count(
                crossAxisCount:  2,
                shrinkWrap:      true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSizes.sm,
                mainAxisSpacing:  AppSizes.sm,
                childAspectRatio: 1.8,
                children: List.generate(4, (_) => ProfileShimmerCard()),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
