import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../../core/constants/colors.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../data/models/community_comment.dart';
import '../../../data/models/community_post.dart';
import '../../../logic/view_models/community_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../logic/view_models/saved_listings_view_model.dart';
import '../profile/other_profile_page.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_action_sheet.dart';
import '../../widgets/app_comment_composer.dart';
import '../../widgets/full_screen_image_viewer.dart';
import 'widgets/community_comment_item.dart';
import 'widgets/community_post_card.dart';

class CommunityDetailArgs {
  final int postId;
  final bool focusComments;
  final CommunityPost? initialPost;

  const CommunityDetailArgs({
    required this.postId,
    this.focusComments = false,
    this.initialPost,
  });
}

class CommunityDetailPage extends StatefulWidget {
  final int postId;
  final bool focusComments;
  final CommunityPost? initialPost;

  const CommunityDetailPage({
    super.key,
    required this.postId,
    this.focusComments = false,
    this.initialPost,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  static const List<String> _reportReasonOptions = [
    'Spam or scam',
    'Harassment or hate speech',
    'Inappropriate content',
    'False information',
    'Other',
  ];

  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final GlobalKey _commentsKey = GlobalKey();

  CommunityPost? _post;
  String? _error;
  bool _isLoading = false;
  bool _isTogglingLike = false;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _loadPost();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPost({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final post = await context.read<CommunityViewModel>().getPostDetail(
      widget.postId,
    );

    if (!mounted) return;

    setState(() {
      _post = post ?? _post;
      _error = post == null
          ? context.read<CommunityViewModel>().error ?? 'Failed to load post.'
          : null;
      _isLoading = false;
    });

    if (widget.focusComments && post != null) {
      _scrollToComments();
    }
  }

  void _scrollToComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final commentContext = _commentsKey.currentContext;
      if (commentContext != null) {
        Scrollable.ensureVisible(
          commentContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      }
    });
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null || _isTogglingLike) return;

    final wasLiked = post.isLikedByMe;
    final optimisticPost = post.copyWith(
      isLikedByMe: !wasLiked,
      likesCount: wasLiked
          ? (post.likesCount > 0 ? post.likesCount - 1 : 0)
          : post.likesCount + 1,
    );

    setState(() {
      _post = optimisticPost;
      _isTogglingLike = true;
    });

    final updated = await context.read<CommunityViewModel>().toggleLike(
      post.id,
      shouldLike: !wasLiked,
    );

    if (!mounted) return;

    setState(() {
      if (updated == null) {
        _post = post;
      } else {
        _post = updated;
      }
      _isTogglingLike = false;
    });

    if (updated == null) {
      AppSnackBar.error(
        context,
        context.read<CommunityViewModel>().error ?? 'Failed to update like.',
      );
    }
  }

  Future<void> _submitComment() async {
    final post = _post;
    final content = _commentController.text.trim();
    if (post == null || content.isEmpty || _isSubmittingComment) return;

    setState(() => _isSubmittingComment = true);

    final updated = await context.read<CommunityViewModel>().addComment(
      postId: post.id,
      content: content,
    );

    if (!mounted) return;

    setState(() {
      _isSubmittingComment = false;
      if (updated != null) {
        _post = updated;
      }
    });

    if (updated == null) {
      AppSnackBar.error(
        context,
        context.read<CommunityViewModel>().error ?? 'Failed to add comment.',
      );
      return;
    }

    _commentController.clear();
    _scrollToComments();
  }

  Future<void> _editComment(CommunityComment comment) async {
    final controller = TextEditingController(text: comment.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: controller,
            maxLength: 500,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Write your comment...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        newContent == null ||
        newContent.isEmpty ||
        newContent == comment.content) {
      return;
    }

    final updated = await context.read<CommunityViewModel>().updateComment(
      postId: widget.postId,
      commentId: comment.id,
      content: newContent,
    );

    if (!mounted) return;
    if (updated == null) {
      AppSnackBar.error(
        context,
        context.read<CommunityViewModel>().error ?? 'Failed to update comment.',
      );
      return;
    }

    setState(() => _post = updated);
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final vm = context.read<CommunityViewModel>();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final updated = await vm.deleteComment(
      postId: widget.postId,
      commentId: comment.id,
    );

    if (!mounted) return;
    if (updated == null) {
      AppSnackBar.error(context, vm.error ?? 'Failed to delete comment.');
      return;
    }

    setState(() => _post = updated);
  }

  void _openUserProfile(int userId) {
    final currentUserId = context.read<UserViewModel>().userId;
    if (currentUserId != null && currentUserId == userId) {
      Navigator.pushNamed(context, AppRoutes.profile);
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.userProfile,
      arguments: OtherProfileArgs(userId: userId),
    );
  }

  Future<void> _sharePost() async {
    await Clipboard.setData(
      ClipboardData(text: 'https://nisittrade.app/community/${widget.postId}'),
    );
    if (!mounted) return;
    AppSnackBar.info(context, 'Post link copied to clipboard.');
  }

  bool _isOwner(CommunityPost post) {
    final userId = context.read<UserViewModel>().userId;
    return userId != null && userId == post.author.id;
  }

  Future<void> _editPost(CommunityPost post) async {
    final retainedImageUrls = List<String>.from(post.orderedImages);
    final newImagePaths = <String>[];
    final controller = TextEditingController(text: post.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) {
        Future<void> pickImage(StateSetter setDialogState) async {
          final remaining = 8 - retainedImageUrls.length - newImagePaths.length;
          if (remaining <= 0) return;
          final picked = await _picker.pickMultiImage(
            imageQuality: 85,
            maxWidth: 1800,
          );
          if (picked.isEmpty) return;
          setDialogState(() {
            final incoming = picked.map((f) => f.path).toList();
            newImagePaths.addAll(incoming.take(remaining));
          });
        }

        return AlertDialog(
          title: const Text('Edit post'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              final totalImages = retainedImageUrls.length + newImagePaths.length;
              final canAddImages = totalImages < 8;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      maxLength: 1000,
                      minLines: 3,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'What\'s on your mind?',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: canAddImages ? () => pickImage(setDialogState) : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.image_outlined, size: 16),
                          label: const Text('Add image'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            totalImages == 0
                                ? 'No images selected'
                                : '$totalImages/8 images attached',
                            style: TextStyle(
                              fontSize: 12,
                              color: totalImages == 0
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              fontWeight: totalImages == 0
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (totalImages > 0) const SizedBox(height: 8),
                    if (totalImages > 0)
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: totalImages,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isExisting = index < retainedImageUrls.length;
                            final image = isExisting
                                ? retainedImageUrls[index]
                                : newImagePaths[index - retainedImageUrls.length];

                            final imageWidget = isExisting
                                ? Image.network(
                                    image,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(image),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  );

                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageWidget,
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (isExisting) {
                                          retainedImageUrls.removeAt(index);
                                        } else {
                                          newImagePaths.removeAt(index - retainedImageUrls.length);
                                        }
                                      });
                                    },
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    final imagesChanged =
        retainedImageUrls.length != post.orderedImages.length ||
        !retainedImageUrls.asMap().entries.every(
          (entry) => entry.value == post.orderedImages[entry.key],
        ) ||
        newImagePaths.isNotEmpty;

    if (!mounted || newContent == null || (newContent == post.content && !imagesChanged)) {
      return;
    }

    if (newContent.isEmpty && retainedImageUrls.isEmpty && newImagePaths.isEmpty) {
      AppSnackBar.info(context, 'Post content or image is required.');
      return;
    }

    final vm = context.read<CommunityViewModel>();
    final updated = await vm.updatePost(
      postId: post.id,
      content: newContent,
      imagePaths: newImagePaths,
      retainedImageUrls: retainedImageUrls,
    );
    if (!mounted) return;

    if (updated == null) {
      AppSnackBar.error(context, vm.error ?? 'Failed to update post.');
      return;
    }

    setState(() => _post = updated);
    AppSnackBar.success(context, 'Post updated.');
  }

  Future<void> _deletePost(CommunityPost post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final vm = context.read<CommunityViewModel>();
    final ok = await vm.deletePost(post.id);
    if (!mounted) return;

    if (!ok) {
      AppSnackBar.error(context, vm.error ?? 'Failed to delete post.');
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _reportPost(CommunityPost post) async {
    var selectedReason = _reportReasonOptions.first;
    final detailsController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Report post'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: _reportReasonOptions
                        .map(
                          (reason) => DropdownMenuItem<String>(
                            value: reason,
                            child: Text(
                              reason,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedReason = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Details (optional)',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    final details = detailsController.text.trim();
    detailsController.dispose();
    if (shouldSubmit != true || !mounted) return;

    final vm = context.read<CommunityViewModel>();
    final ok = await vm.reportPost(
      postId: post.id,
      reason: selectedReason,
      details: details.isEmpty ? null : details,
    );

    if (!mounted) return;
    if (!ok) {
      AppSnackBar.error(context, vm.error ?? 'Failed to submit report.');
      return;
    }

    AppSnackBar.success(context, 'Report submitted.');
  }

  Future<void> _showPostActions() async {
    final post = _post;
    if (!mounted || post == null) return;
    final effectivePost = post;
    final isOwner = _isOwner(effectivePost);

    await AppActionSheet.show(
      context,
      title: 'Post options',
      items: [
        if (isOwner)
          AppActionSheetItem(
            label: 'Edit post',
            icon: Icons.edit_outlined,
            onTap: () => _editPost(effectivePost),
          ),
        if (isOwner)
          AppActionSheetItem(
            label: 'Delete post',
            icon: Icons.delete_outline,
            isDestructive: true,
            onTap: () => _deletePost(effectivePost),
          ),
        AppActionSheetItem(
          label: 'Copy link',
          icon: Icons.link,
          onTap: _sharePost,
        ),
        AppActionSheetItem(
          label: effectivePost.isSavedByMe ? 'Unsave post' : 'Save post',
          icon: effectivePost.isSavedByMe
              ? Icons.bookmark_remove_outlined
              : Icons.bookmark_add_outlined,
          onTap: () => _toggleSavePost(effectivePost),
        ),
        if (!isOwner)
          AppActionSheetItem(
            label: 'Report post',
            icon: Icons.flag_outlined,
            isDestructive: true,
            onTap: () => _reportPost(effectivePost),
          ),
      ],
    );
  }

  Future<void> _toggleSavePost(CommunityPost post) async {
    final vm = context.read<CommunityViewModel>();
    final savedListingsVm = context.read<SavedListingsViewModel>();
    final isSaved = post.isSavedByMe;
    
    final updated = await vm.toggleSave(post.id, shouldSave: !isSaved);
    if (!mounted) return;

    if (updated == null) {
      AppSnackBar.error(context, vm.error ?? 'Failed to update saved status.');
      return;
    }

    // Update SavedListingsViewModel
    if (updated.isSavedByMe) {
      savedListingsVm.addSavedPostLocally(updated);
    } else {
      savedListingsVm.removeSavedPostLocally(postId: post.id);
    }

    setState(() => _post = updated);
    AppSnackBar.info(
      context,
      updated.isSavedByMe ? 'Post saved.' : 'Post removed from saved.',
    );
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    if (!mounted || images.isEmpty) return;
    final safeIndex = initialIndex.clamp(0, images.length - 1);
    FullScreenImageViewer.show(
      context,
      images[safeIndex],
      allImages: images,
      initialIndex: safeIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Detail')),
      body: _isLoading && post == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null && post == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppErrorMessages.resolve(_error),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadPost,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _loadPost(silent: true),
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      children: [
                        if (post != null)
                          CommunityPostCard(
                            post: post,
                            isLiked: post.isLikedByMe,
                            onTap: () {},
                            onImageTap: (index) =>
                                _showImageViewer(post.orderedImages, index),
                            onUserTap: () => _openUserProfile(post.author.id),
                            onLikeTap: _isTogglingLike ? null : _toggleLike,
                            onCommentTap: _scrollToComments,
                            onShareTap: _sharePost,
                            onMoreTap: _showPostActions,
                          ),
                        Padding(
                          key: _commentsKey,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                'Comments',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (post?.commentsCount ?? 0).toString(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildComments(),
                      ],
                    ),
                  ),
                ),
                _buildCommentComposer(),
              ],
            ),
    );
  }

  Widget _buildComments() {
    final comments = _post?.comments ?? const <CommunityComment>[];
    final userId = context.read<UserViewModel>().userId;

    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Text(
          'No comments yet. Be the first to comment.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: comments.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 16, color: AppColors.border),
      itemBuilder: (context, index) {
        final comment = comments[index];
        final handle = buildSchoolShortName(
          universityName: comment.user?.university?.name,
          universityDomain: comment.user?.university?.domain,
          fallback: '',
        );
        return CommunityCommentItem(
          avatarUrl: comment.user?.profileImage,
          displayName: comment.user?.fullName ?? 'User',
          handle: handle,
          content: comment.content,
          createdAt: comment.createdAt,
          canEdit: userId != null && userId == comment.userId,
          onUserTap: () => _openUserProfile(comment.userId),
          onEdit: () => _editComment(comment),
          onDelete: () => _deleteComment(comment),
        );
      },
    );
  }

  Widget _buildCommentComposer() {
    return AppCommentComposer(
      controller: _commentController,
      focusNode: _commentFocusNode,
      onSend: _submitComment,
      isSubmitting: _isSubmittingComment,
      maxLength: 500,
      pinnedToBottom: true,
    );
  }

}
