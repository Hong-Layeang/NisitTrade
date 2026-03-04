import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../models/student.dart';
import '../../../models/user_profile.dart';

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
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
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
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: AppColors.surface,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reusable follow/add person button
class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback? onTap;

  const FollowButton({
    super.key,
    this.isFollowing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isFollowing
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isFollowing ? Icons.person : Icons.person_add_outlined,
          color: isFollowing ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

/// List tile for a [UserProfile] — used on the Students search tab.
class UserProfileListTile extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onTap;

  const UserProfileListTile({
    super.key,
    required this.user,
    this.onTap,
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
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}