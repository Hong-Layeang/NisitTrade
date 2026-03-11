import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../data/models/community_comment.dart';
import '../../../data/models/community_post.dart';
import '../../../logic/view_models/community_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../profile/other_profile_page.dart';
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
  final ScrollController _scrollController = ScrollController();
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

    final post = await context.read<CommunityViewModel>().getPostDetail(widget.postId);

    if (!mounted) return;

    setState(() {
      _post = post ?? _post;
      _error = post == null ? context.read<CommunityViewModel>().error ?? 'Failed to load post.' : null;
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

      _commentFocusNode.requestFocus();
    });
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null || _isTogglingLike) return;

    setState(() => _isTogglingLike = true);
    final updated = await context.read<CommunityViewModel>().toggleLike(
      post.id,
      shouldLike: !post.isLikedByMe,
    );

    if (!mounted) return;

    setState(() {
      _post = updated ?? _post;
      _isTogglingLike = false;
    });

    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<CommunityViewModel>().error ?? 'Failed to update like.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<CommunityViewModel>().error ?? 'Failed to add comment.')),
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
            decoration: const InputDecoration(hintText: 'Write your comment...'),
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

    if (!mounted || newContent == null || newContent.isEmpty || newContent == comment.content) {
      return;
    }

    final updated = await context.read<CommunityViewModel>().updateComment(
      postId: widget.postId,
      commentId: comment.id,
      content: newContent,
    );

    if (!mounted) return;
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<CommunityViewModel>().error ?? 'Failed to update comment.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Failed to delete comment.')),
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post link copied to clipboard.')),
    );
  }

  Future<void> _showPostActions() async {
    final post = _post;
    if (!mounted || post == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View profile'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openUserProfile(post.author.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.near_me_outlined),
                title: const Text('Share post'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _sharePost();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
      ),
      body: _isLoading && post == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null && post == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
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

    return Column(
      children: [
        for (var i = 0; i < comments.length; i++) ...[
          _buildCommentItem(
            comment: comments[i],
            canEdit: userId != null && userId == comments[i].userId,
          ),
          if (i != comments.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 16, color: AppColors.border),
            ),
        ],
      ],
    );
  }

  Widget _buildCommentItem({
    required CommunityComment comment,
    required bool canEdit,
  }) {
    final handle = buildSchoolShortName(
      universityName: comment.user?.university?.name,
      universityDomain: comment.user?.university?.domain,
      fallback: '',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openUserProfile(comment.userId),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface,
              backgroundImage: (comment.user?.profileImage?.isNotEmpty ?? false)
                  ? NetworkImage(comment.user!.profileImage!)
                  : null,
              child: (comment.user?.profileImage?.isNotEmpty ?? false)
                  ? null
                  : const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 18,
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
                      child: InkWell(
                        onTap: () => _openUserProfile(comment.userId),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Text(
                              comment.user?.fullName ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            if (handle.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '@$handle',
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
                    if (canEdit)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editComment(comment);
                          }
                          if (value == 'delete') {
                            _deleteComment(comment);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(comment.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentComposer() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSubmittingComment ? null : _submitComment,
              icon: _isSubmittingComment
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
