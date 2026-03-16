import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/student.dart';
import '../../../domain/entities/user_entity.dart';
import 'app_loading.dart';

class StudentListTile extends StatelessWidget {
  final Student student;
  final bool isFollowing;
  final VoidCallback? onTap;
  final VoidCallback? onFollowTap;

  const StudentListTile({
    super.key,
    required this.student,
    this.isFollowing = false,
    this.onTap,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.surface,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: student.avatarUrl,
              radius: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.username,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            FollowButton(
              isFollowing: isFollowing,
              onTap: onFollowTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable user avatar with proper error handling
class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CircleAvatar(
        key: ValueKey('avatar_$imageUrl'),
        radius: radius,
        backgroundColor: AppColors.surface,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            useOldImageOnUrlChange: true,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            errorWidget: (context, url, error) {
              return Container(
                width: radius * 2,
                height: radius * 2,
                color: AppColors.surface,
                child: Icon(
                  fallbackIcon,
                  color: AppColors.textSecondary,
                  size: radius,
                ),
              );
            },
            progressIndicatorBuilder: (context, url, progress) {
              return Container(
                width: radius * 2,
                height: radius * 2,
                color: AppColors.surface,
                child: Center(
                  child: AppLoadingIndicator(
                    size: radius,
                    strokeWidth: 2,
                    value: progress.progress,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Reusable follow/add person button
class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback? onTap;

  const FollowButton({
    super.key,
    this.isFollowing = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isFollowing
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: 24,
          height: 24,
          child: isLoading
              ? const AppLoadingIndicator(size: 24, strokeWidth: 2)
              : Icon(
                  isFollowing ? Icons.person : Icons.person_add_outlined,
                  color: isFollowing ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
        ),
      ),
    );
  }
}

class UserProfileListTile extends StatelessWidget {
  final UserEntity user;
  final bool isFollowing;
  final bool isFollowLoading;
  final bool showFollowButton;
  final VoidCallback? onTap;
  final VoidCallback? onFollowTap;

  const UserProfileListTile({
    super.key,
    required this.user,
    this.isFollowing = false,
    this.isFollowLoading = false,
    this.showFollowButton = true,
    this.onTap,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.profileImage ?? '';
    final university = user.university?.name ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surface, width: 1),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(imageUrl: avatarUrl, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (university.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      university,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showFollowButton)
              FollowButton(
                isFollowing: isFollowing,
                isLoading: isFollowLoading,
                onTap: onFollowTap,
              ),
          ],
        ),
      ),
    );
  }
}