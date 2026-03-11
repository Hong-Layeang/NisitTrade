import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../data/models/comment.dart';
import '../../../../domain/entities/university_entity.dart';
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
    return Selector<
      UserViewModel,
      ({
        int? userId,
        String? profileImage,
        String? fullName,
        UniversityEntity? university,
      })
    >(
      selector: (_, vm) => (
        userId: vm.userId,
        profileImage: vm.profile?.profileImage,
        fullName: vm.profile?.fullName,
        university: vm.profile?.university,
      ),
      builder: (context, userData, _) {
        final isCurrentUser =
            userData.userId != null && comment.userId == userData.userId;
        final commentAvatarUrl = isCurrentUser
            ? userData.profileImage
            : comment.user?.profileImage;
        final displayName = isCurrentUser
            ? (userData.fullName ?? comment.user?.fullName ?? 'User')
            : (comment.user?.fullName ?? 'User');
        final university = isCurrentUser
            ? (userData.university ?? comment.user?.university?.toEntity())
            : comment.user?.university?.toEntity();
        final schoolShortName = university == null
            ? null
            : '@${ProfileUtils.getSchoolShortName(university)}';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: onUserTap,
                child: RepaintBoundary(
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surface,
                    backgroundImage: commentAvatarUrl != null
                        ? CachedNetworkImageProvider(commentAvatarUrl)
                              as ImageProvider
                        : null,
                    child: commentAvatarUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 18,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onUserTap,
                          child: Row(
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              if (schoolShortName != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  schoolShortName,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isCurrentUser && (onEdit != null || onDelete != null))
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_horiz,
                              color: AppColors.textSecondary,
                              size: 18,
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
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
