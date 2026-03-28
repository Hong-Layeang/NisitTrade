import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import '../../../../core/constants/colors.dart';
import '../../../widgets/user_widgets.dart';

class CommunityCommentItem extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final String? handle;
  final String content;
  final DateTime createdAt;
  final bool canEdit;
  final VoidCallback onUserTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommunityCommentItem({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.handle,
    required this.content,
    required this.createdAt,
    required this.canEdit,
    required this.onUserTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final safeHandle = (handle ?? '').trim();
    final showEditMenu = canEdit && (onEdit != null || onDelete != null);
    final normalizedName = displayName.trim().isEmpty
        ? 'User'
        : displayName.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: GestureDetector(
            onTap: onUserTap,
            child: UserAvatar(
              imageUrl: avatarUrl ?? '',
              displayName: normalizedName,
              radius: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onUserTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              normalizedName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (safeHandle.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                safeHandle.startsWith('@')
                                    ? safeHandle
                                    : '@$safeHandle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showEditMenu)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit?.call();
                          }
                          if (value == 'delete') {
                            onDelete?.call();
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
              const SizedBox(height: 0),
              Text(
                content,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Timeago(
                date: createdAt,
                builder: (context, value) => Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
