import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../logic/view_models/community_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../data/models/community_post.dart';
import '../../widgets/app_action_sheet.dart';
import '../../widgets/app_snack_bar.dart';
import '../profile/other_profile_page.dart';
import 'community_detail_page.dart';
import 'widgets/community_post_card.dart';
import 'widgets/post_composer.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _reportReasonOptions = [
    'Spam or scam',
    'Harassment or hate speech',
    'Inappropriate content',
    'False information',
    'Other',
  ];

  late final TabController _tabController;
  late final ScrollController _scrollController;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();
  bool _isComposerOpen = true;
  final List<String> _selectedImagePaths = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityViewModel>().load(feed: 'community');
    });
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isComposerOpen) {
        setState(() => _isComposerOpen = false);
      }
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      final feed = _tabController.index == 0 ? 'community' : 'following';
      context.read<CommunityViewModel>().load(feed: feed);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _scrollController.removeListener(_onScroll);
    _postController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final remaining = 8 - _selectedImagePaths.length;
    if (remaining <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 8 images allowed')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1800,
    );

    if (!mounted || picked.isEmpty) return;

    setState(() {
      final incoming = picked.map((f) => f.path).toList();
      final allowed = incoming.take(remaining);
      _selectedImagePaths.addAll(allowed);
    });

    if (picked.length > remaining && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the first 8 images were kept')),
      );
    }
  }

  Future<void> _submitPost() async {
    final vm = context.read<CommunityViewModel>();
    final content = _postController.text.trim();
    if (content.isEmpty && _selectedImagePaths.isEmpty) {
      return;
    }

    final ok = await vm.createPost(
      content: content,
      imagePaths: _selectedImagePaths,
    );
    if (!mounted) return;

    if (ok) {
      _postController.clear();
      setState(() {
        _selectedImagePaths.clear();
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted to community')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.error ?? 'Failed to create post')),
    );
  }

  Future<void> _openPostDetail(
    CommunityPost post, {
    bool focusComments = false,
  }) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.communityDetail,
      arguments: CommunityDetailArgs(
        postId: post.id,
        focusComments: focusComments,
        initialPost: post,
      ),
    );
  }

  Future<void> _toggleLike(CommunityPost post) async {
    final vm = context.read<CommunityViewModel>();
    final updated = await vm.toggleLike(post.id, shouldLike: !post.isLikedByMe);
    if (!mounted || updated != null) return;
    AppSnackBar.error(context, vm.error ?? 'Failed to update like.');
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

  Future<void> _sharePost(CommunityPost post) async {
    final shareLink = 'https://nisittrade.app/community/${post.id}';
    await Clipboard.setData(ClipboardData(text: shareLink));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post link copied to clipboard.')),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post content or image is required.')),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post updated.')),
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted.')),
    );
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
                            child: Text(reason, overflow: TextOverflow.ellipsis),
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
                    decoration: const InputDecoration(labelText: 'Details (optional)'),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted.')),
    );
  }

  Future<void> _toggleSavePost(CommunityPost post) async {
    final vm = context.read<CommunityViewModel>();
    final updated = await vm.toggleSave(post.id, shouldSave: !post.isSavedByMe);
    if (!mounted) return;

    if (updated == null) {
      AppSnackBar.error(context, vm.error ?? 'Failed to update saved status.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated.isSavedByMe ? 'Post saved.' : 'Post removed from saved.'),
      ),
    );
  }

  Future<void> _showPostActions(CommunityPost post) async {
    if (!mounted) return;
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
          onTap: () => _sharePost(effectivePost),
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

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserViewModel>().profile;
    final handle = buildSchoolShortName(
      universityName: currentUser?.university?.name,
      universityDomain: currentUser?.university?.domain,
      fallback: 'campus',
    );
    return Column(
      children: [
        _buildTabBar(context, handle: handle),
        ListenableBuilder(
          listenable: _tabController,
          builder: (_, _) {
            if (_tabController.index != 0) return const SizedBox.shrink();
            return Selector<CommunityViewModel, bool>(
              selector: (_, vm) => vm.isPosting,
              builder: (_, isPosting, _) => PostComposer(
                isOpen: _isComposerOpen,
                isPosting: isPosting,
                controller: _postController,
                selectedImagePaths: _selectedImagePaths,
                onPickImage: _pickImage,
                onRemoveImage: (index) =>
                    setState(() => _selectedImagePaths.removeAt(index)),
                onToggle: () =>
                    setState(() => _isComposerOpen = !_isComposerOpen),
                onSend: () => _submitPost(),
              ),
            );
          },
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCommunityTab(),
              _buildFollowingTab(handle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(
    BuildContext context, {
    required String handle,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600) ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500) ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Community',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (handle.isNotEmpty)
                    TextSpan(
                      text: ' @$handle',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Tab(text: 'Following'),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return _buildFeedTab(
      feed: 'community',
      emptyMessage: 'No community posts yet. Be the first to share.',
    );
  }

  Widget _buildFollowingTab(String handle) {
    return _buildFeedTab(
      feed: 'following',
      emptyMessage: handle.isEmpty
          ? 'No posts from people you follow in this community yet.'
          : 'No posts from people you follow in @$handle yet.',
    );
  }

  Widget _buildFeedTab({
    required String feed,
    required String emptyMessage,
  }) {
    return Consumer<CommunityViewModel>(
      builder: (context, vm, _) {
        final isCurrentFeed = vm.activeFeed == feed;

        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (vm.error != null && vm.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppErrorMessages.resolve(vm.error),
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: vm.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => vm.load(feed: feed),
          child: !isCurrentFeed
                    ? const SizedBox.shrink()
                    : vm.posts.isEmpty
                    ? ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              emptyMessage,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                        itemCount: vm.posts.length,
                        itemBuilder: (context, index) {
                          final post = vm.posts[index];
                          return CommunityPostCard(
                            post: post,
                            isLiked: post.isLikedByMe,
                            onTap: () => _openPostDetail(post),
                            onUserTap: () => _openUserProfile(post.author.id),
                            onLikeTap: () => _toggleLike(post),
                            onCommentTap: () => _openPostDetail(post, focusComments: true),
                            onShareTap: () => _sharePost(post),
                            onMoreTap: () => _showPostActions(post),
                          );
                        },
                      ),
        );
      },
    );
  }
}
