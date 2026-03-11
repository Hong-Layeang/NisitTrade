import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

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

  bool _isValidNetworkUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
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
                    backgroundImage: _isValidNetworkUrl(commentAvatarUrl)
                      ? CachedNetworkImageProvider(commentAvatarUrl!.trim())
                              as ImageProvider
                        : null,
                    child: !_isValidNetworkUrl(commentAvatarUrl)
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
                  Timeago(
                    date: comment.createdAt,
                    builder: (context, value) => Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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
