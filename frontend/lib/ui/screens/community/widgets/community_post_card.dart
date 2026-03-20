import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import '../../../../data/models/community_post.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/school_short_name.dart';
import '../../../../logic/view_models/user_view_model.dart';
import '../../../widgets/app_action_chip.dart';
import '../../../widgets/user_widgets.dart';

class CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final bool isLiked;
  final VoidCallback? onTap;
  final ValueChanged<int>? onImageTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.isLiked = false,
    this.onTap,
    this.onImageTap,
    this.onUserTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onShareTap,
    this.onMoreTap,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  int _currentImageIndex = 0;

  String _uniHandle() {
    return buildSchoolShortName(
      universityName: widget.post.author.university?.name,
      universityDomain: widget.post.author.university?.domain,
      email: widget.post.author.email,
      fallback: '',
    );
  }

  String? _resolveAvatarUrl(BuildContext context) {
    final currentUser = context
        .select<UserViewModel, ({int? id, String? image})>(
          (vm) => (id: vm.userId, image: vm.profile?.profileImage),
        );

    final isCurrentUserPost =
        currentUser.id != null && currentUser.id == widget.post.author.id;
    if (isCurrentUserPost && (currentUser.image?.isNotEmpty ?? false)) {
      return currentUser.image;
    }

    if (widget.post.author.profileImage?.isNotEmpty ?? false) {
      return widget.post.author.profileImage;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    const contentPadding = EdgeInsets.symmetric(horizontal: 16);
    final handle = _uniHandle();
    final avatarUrl = _resolveAvatarUrl(context) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: contentPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      imageUrl: avatarUrl,
                      displayName: widget.post.author.fullName,
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: widget.onUserTap,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                              child: Text(
                                widget.post.author.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          if (handle.isNotEmpty)
                            InkWell(
                              onTap: widget.onUserTap,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 1,
                                ),
                                child: Text(
                                  '@$handle',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Timeago(
                          date: widget.post.createdAt,
                          builder: (context, value) => Text(
                            value,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            onPressed: widget.onMoreTap,
                            icon: const Icon(Icons.more_horiz, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: contentPadding,
                child: Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.post.orderedImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              if (widget.onImageTap != null) {
                widget.onImageTap!(_currentImageIndex);
                return;
              }
              widget.onTap?.call();
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: widget.post.orderedImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final imageUrl = widget.post.orderedImages[index];
                      final isNetwork =
                          imageUrl.startsWith('http://') ||
                          imageUrl.startsWith('https://');

                      if (!isNetwork) {
                        return Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined),
                              ),
                            );
                          },
                        );
                      }

                      return RepaintBoundary(
                        child: CachedNetworkImage(
                          key: ValueKey('post_image_${widget.post.id}_$index'),
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          useOldImageOnUrlChange: true,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (context, url) => Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  if (widget.post.orderedImages.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${widget.post.orderedImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (widget.post.orderedImages.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.post.orderedImages.length > 8
                              ? 8
                              : widget.post.orderedImages.length,
                          (index) {
                            int displayIndex = index;
                            if (widget.post.orderedImages.length > 8 &&
                                _currentImageIndex > 3) {
                              displayIndex = _currentImageIndex - 3 + index;
                              if (displayIndex >=
                                  widget.post.orderedImages.length) {
                                displayIndex =
                                    widget.post.orderedImages.length -
                                    8 +
                                    index;
                              }
                            }
                            final isActive = displayIndex == _currentImageIndex;
                            return Container(
                              width: isActive ? 8 : 6,
                              height: isActive ? 8 : 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Padding(
          padding: contentPadding,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                AppActionChip(
                  icon: Icon(
                    widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.isLiked
                        ? Colors.redAccent
                        : AppColors.textPrimary,
                    size: 18,
                  ),
                  label: NumberFormatters.formatCount(widget.post.likesCount),
                  labelColor: widget.isLiked
                      ? Colors.redAccent
                      : AppColors.textPrimary,
                  onTap: widget.onLikeTap,
                ),
                const SizedBox(width: 6),
                AppActionChip(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                  label: NumberFormatters.formatCount(
                    widget.post.commentsCount,
                  ),
                  labelColor: AppColors.textPrimary,
                  onTap: widget.onCommentTap,
                ),
                const Spacer(),
                AppActionChip(
                  icon: const Icon(
                    Icons.near_me_outlined,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                  label: 'Share',
                  labelColor: AppColors.textPrimary,
                  onTap: widget.onShareTap,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
      ],
    );
  }
}
