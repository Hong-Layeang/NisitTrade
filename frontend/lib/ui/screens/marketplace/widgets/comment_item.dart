import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/school_short_name.dart';
import '../../../../data/models/comment.dart';
import '../../../../domain/entities/university_entity.dart';
import '../../../../logic/view_models/user_view_model.dart';
import '../../community/widgets/community_comment_item.dart';

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
        final handle = buildSchoolShortName(
          universityName: university?.name,
          universityDomain: university?.domain,
          fallback: '',
        );

        return CommunityCommentItem(
          avatarUrl: commentAvatarUrl,
          displayName: displayName,
          handle: handle,
          content: comment.content,
          createdAt: comment.createdAt,
          canEdit: isCurrentUser,
          onUserTap: onUserTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}
