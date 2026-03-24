import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../controllers/profile_controller.dart';

/// Circular avatar with optional edit FAB overlay.
/// Shows shimmer while loading, falls back to initials if no photo.
class ProfileAvatar extends ConsumerWidget {
  final double size;
  final bool   editable;

  const ProfileAvatar({
    super.key,
    this.size     = AppSizes.avatarLg,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final editState = editable ? ref.watch(profileControllerProvider) : null;

    return userAsync.when(
      loading: () => _ShimmerAvatar(size: size),
      error:   (_, __) => _InitialsAvatar(name: '?', size: size),
      data: (user) {
        if (user == null) return _InitialsAvatar(name: '?', size: size);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _AvatarImage(
              photoUrl: user.effectivePhotoUrl,
              name:     user.name,
              gender:   user.gender,
              size:     size,
            ),
            if (editable) ...[
              // Show upload progress ring
              if (editState?.isSaving == true)
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: editState?.uploadProgress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              // Edit FAB
              Positioned(
                bottom: 0,
                right:  0,
                child: GestureDetector(
                  onTap: () {
                    final uid = ref.read(authStateProvider).valueOrNull?.uid;
                    if (uid != null) {
                      ref
                          .read(profileControllerProvider.notifier)
                          .uploadProfilePhoto(uid);
                    }
                  },
                  child: Container(
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:        AppColors.accent,
                      shape:        BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset:     const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primaryDark,
                      size:  18,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── _AvatarImage ──────────────────────────────────────────────

class _AvatarImage extends StatelessWidget {
  final String photoUrl;
  final String name;
  final String gender;
  final double size;

  const _AvatarImage({
    required this.photoUrl,
    required this.name,
    required this.gender,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    String url = photoUrl;
    if (url.isEmpty) {
      if (gender == 'Male') {
        url = 'https://xsgames.co/randomusers/avatar.php?g=male';
      } else if (gender == 'Female') {
        url = 'https://xsgames.co/randomusers/avatar.php?g=female';
      }
    }

    if (url.isNotEmpty) {
      return _CircleContainer(
        size: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _ShimmerAvatar(size: size);
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('[Avatar] load error: $error');
            return _InitialsAvatar(name: name, size: size);
          },
        ),
      );
    }
    return _InitialsAvatar(name: name, size: size);
  }
}

// ── _InitialsAvatar ───────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _InitialsAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    return _CircleContainer(
      size: size,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.cardGradient,
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color:      Colors.white,
              fontSize:   size * 0.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── _ShimmerAvatar ────────────────────────────────────────────

class _ShimmerAvatar extends StatelessWidget {
  final double size;
  const _ShimmerAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:     Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: _CircleContainer(
        size:  size,
        child: Container(color: Colors.white),
      ),
    );
  }
}

// ── _CircleContainer ──────────────────────────────────────────

class _CircleContainer extends StatelessWidget {
  final double size;
  final Widget child;
  const _CircleContainer({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape:   BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withOpacity(0.4),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color:      AppColors.primary.withOpacity(0.2),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
