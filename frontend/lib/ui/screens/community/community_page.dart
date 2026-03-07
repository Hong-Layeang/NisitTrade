import 'package:flutter/material.dart';
import '../../../data/models/community_post.dart';
import '../../../data/models/seller.dart';
import '../../../core/constants/colors.dart';
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
  List<CommunityPost> _posts = [];
  List<CommunityPost> _friendPosts = [];
  final Set<String> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final author = Seller(
      id: 1,
      fullName: 'Nisit Community',
      email: 'community@cadt.edu.kh',
      profileImage: 'https://i.pravatar.cc/300?img=25',
      provider: null,
      role: 'admin',
      universityId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final posts = [
      CommunityPost(
        id: '1',
        author: author,
        content:
            'Welcome to the NisitTrade community! Share tips, deals, and campus finds here.',
        imageUrl:
            'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=900',
        likes: 128,
        comments: 14,
        timeAgo: '2h ago',
      ),
      CommunityPost(
        id: '2',
        author: author,
        content:
            'Reminder: Be kind and keep posts relevant to campus trading. Happy selling!',
        imageUrl: null,
        likes: 64,
        comments: 8,
        timeAgo: '1d ago',
      ),
    ];

    setState(() {
      _posts = posts;
      _friendPosts = [];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(context),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCommunityTab(),
              _buildFriendsTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ) ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Community @cadt'),
          Tab(text: 'Friends'),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const PostComposer();
        }

        final post = _posts[index - 1];
        return CommunityPostCard(
          post: post,
          isLiked: _likedPosts.contains(post.id),
          onLikeTap: () {
            setState(() {
              if (_likedPosts.contains(post.id)) {
                _likedPosts.remove(post.id);
              } else {
                _likedPosts.add(post.id);
              }
            });
          },
        );
      },
      itemCount: _posts.length + 1,
    );
  }

  Widget _buildFriendsTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_friendPosts.isEmpty) {
      return Center(
        child: Text(
          'No friend posts yet',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      itemCount: _friendPosts.length,
      itemBuilder: (context, index) {
        final post = _friendPosts[index];
        return CommunityPostCard(
          post: post,
          isLiked: _likedPosts.contains(post.id),
          onLikeTap: () {
            setState(() {
              if (_likedPosts.contains(post.id)) {
                _likedPosts.remove(post.id);
              } else {
                _likedPosts.add(post.id);
              }
            });
          },
        );
      },
    );
  }
}
