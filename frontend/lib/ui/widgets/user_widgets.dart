import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../data/models/student.dart';
import '../../../domain/entities/user_entity.dart';
import 'app_loading.dart';
import 's3_cached_network_image.dart';

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
            bottom: BorderSide(color: AppColors.surface, width: 1),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: student.avatarUrl ?? '',
              displayName: student.name,
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
            FollowButton(isFollowing: isFollowing, onTap: onFollowTap),
          ],
        ),
      ),
    );
  }
}

/// Reusable user avatar with proper error handling
class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final String? displayName;
  final double radius;
  final bool showStatusDot;
  final Color statusDotColor;
  final Color statusDotBorderColor;
  final double statusDotSize;
  final double statusDotBorderWidth;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.displayName,
    this.radius = 24,
    this.showStatusDot = false,
    this.statusDotColor = AppColors.primary,
    this.statusDotBorderColor = Colors.white,
    this.statusDotSize = 12,
    this.statusDotBorderWidth = 2,
  });

  String _initials() {
    final name = displayName?.trim() ?? '';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildInitialsFallback() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          _initials(),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: radius * 0.42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = imageUrl.trim();
    final resolvedImageUrl = trimmedImageUrl.isEmpty
        ? ''
        : ImageUrlHelper.getFullImageUrl(trimmedImageUrl);
    final hasValidImage = ImageUrlHelper.isValidUrl(resolvedImageUrl);

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            key: ValueKey('avatar_$resolvedImageUrl'),
            radius: radius,
            backgroundColor: AppColors.surface,
            child: ClipOval(
              child: hasValidImage
                  ? S3CachedNetworkImage(
                      imageUrl: resolvedImageUrl,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      useOldImageOnUrlChange: true,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      errorWidget: (context, url, error) {
                        return _buildInitialsFallback();
                      },
                      progressIndicatorBuilder: (context, url, progress) {
                        final total = progress.totalSize ?? 1;
                        final downloaded = progress.downloaded;
                        final progressValue = total > 0
                            ? (downloaded / total)
                            : 0.0;
                        return Container(
                          width: radius * 2,
                          height: radius * 2,
                          color: AppColors.surface,
                          child: Center(
                            child: AppLoadingIndicator(
                              size: radius,
                              strokeWidth: 2,
                              value: progressValue,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    )
                  : _buildInitialsFallback(),
            ),
          ),
          if (showStatusDot)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: statusDotSize,
                height: statusDotSize,
                decoration: BoxDecoration(
                  color: statusDotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusDotBorderColor,
                    width: statusDotBorderWidth,
                  ),
                ),
              ),
            ),
        ],
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
                  color: isFollowing
                      ? AppColors.primary
                      : AppColors.textSecondary,
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
  final String? subtitle;
  final bool showStatusDot;
  final Color? statusDotColor;
  final VoidCallback? onTap;
  final VoidCallback? onFollowTap;

  const UserProfileListTile({
    super.key,
    required this.user,
    this.isFollowing = false,
    this.isFollowLoading = false,
    this.showFollowButton = true,
    this.subtitle,
    this.showStatusDot = false,
    this.statusDotColor,
    this.onTap,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.profileImage ?? '';
    final secondaryText = subtitle ?? user.university?.name ?? '';

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
            UserAvatar(
              imageUrl: avatarUrl,
              displayName: user.fullName,
              radius: 28,
              showStatusDot: showStatusDot,
              statusDotColor: statusDotColor ?? AppColors.textSecondary,
            ),
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
                  if (secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
