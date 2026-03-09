import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../data/models/comment.dart';
import '../../../../logic/view_models/user_view_model.dart';
import '../../profile/widgets/profile_widgets.dart';

/// Widget to display a single comment with user info and actions
class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback onUserTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onUserTap,
    this.onEdit,
    this.onDelete,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserViewModel,
        ({
          int? userId,
          String? profileImage,
        })>(
      selector: (_, vm) => (
        userId: vm.userId,
        profileImage: vm.profile?.profileImage,
      ),
      builder: (context, userData, _) {
        final isCurrentUser =
            userData.userId != null && comment.userId == userData.userId;
        final commentAvatarUrl = isCurrentUser
            ? userData.profileImage
            : comment.user?.profileImage;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onUserTap,
              child: RepaintBoundary(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surface,
                  backgroundImage: commentAvatarUrl != null
                      ? CachedNetworkImageProvider(commentAvatarUrl) as ImageProvider
                      : null,
                  child: commentAvatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.textSecondary, size: 18)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onUserTap,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.user?.fullName ?? 'User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              if (comment.user?.university != null)
                                Text(
                                  ProfileUtils.getSchoolShortName(comment.user!.university!.toEntity()),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (isCurrentUser && (onEdit != null || onDelete != null))
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onSelected: (value) {
                            if (value == 'edit' && onEdit != null) {
                              onEdit!();
                            } else if (value == 'delete' && onDelete != null) {
                              onDelete!();
                            }
                          },
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(comment.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
