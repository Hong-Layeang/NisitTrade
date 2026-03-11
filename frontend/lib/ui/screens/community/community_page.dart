import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../logic/view_models/community_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../data/models/community_post.dart';
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
    if (mounted) {
      setState(() {});
    }

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

  Future<void> _submitPost(CommunityViewModel vm) async {
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
    if (!mounted) return;
    await context.read<CommunityViewModel>().getPostDetail(post.id);
  }

  Future<void> _toggleLike(CommunityPost post) async {
    final vm = context.read<CommunityViewModel>();
    final updated = await vm.toggleLike(post.id, shouldLike: !post.isLikedByMe);
    if (!mounted || updated != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.error ?? 'Failed to update like.')),
    );
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

  Future<void> _showPostActions(CommunityPost post) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View detail'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openPostDetail(post);
                },
              ),
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
                  _sharePost(post);
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
    final currentUser = context.watch<UserViewModel>().profile;
    final handle = buildSchoolShortName(
      universityName: currentUser?.university?.name,
      universityDomain: currentUser?.university?.domain,
      fallback: 'campus',
    );
    final isCommunitySelected = _tabController.index == 0;

    return Column(
      children: [
        _buildTabBar(
          context,
          handle: handle,
          isCommunitySelected: isCommunitySelected,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCommunityTab(),
              _buildFollowingTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(
    BuildContext context, {
    required String handle,
    required bool isCommunitySelected,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final baseActiveColor = AppColors.primary;
    final baseInactiveColor = AppColors.textSecondary;
    final communityBaseColor = isCommunitySelected ? baseActiveColor : baseInactiveColor;

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
                  TextSpan(
                    text: 'Community',
                    style: TextStyle(
                      color: communityBaseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (handle.isNotEmpty)
                    TextSpan(
                      text: ' @$handle',
                      style: TextStyle(
                        color: communityBaseColor,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildFollowingTab(BuildContext context) {
    return _buildFeedTab(
      feed: 'following',
      emptyMessage: 'No posts from people you follow yet.',
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
                  vm.error!,
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

        return Column(
          children: [
            PostComposer(
              isOpen: _isComposerOpen,
              isPosting: vm.isPosting,
              controller: _postController,
              selectedImagePaths: _selectedImagePaths,
              onPickImage: _pickImage,
              onRemoveImage: (index) {
                setState(() {
                  _selectedImagePaths.removeAt(index);
                });
              },
              onToggle: () {
                setState(() {
                  _isComposerOpen = !_isComposerOpen;
                });
              },
              onSend: () => _submitPost(vm),
            ),
            Expanded(
              child: RefreshIndicator(
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
              ),
            ),
          ],
        );
      },
    );
  }
}
