import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../logic/view_models/user_view_model.dart';
import '../../logic/view_models/chat_view_model.dart';
import 'package:provider/provider.dart';
import '../screens/community/community_page.dart';
import '../screens/marketplace/marketplace_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/search/search_page.dart';
import '../screens/sell/sell_page.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/app_bottom_nav.dart';
import '../../core/navigation/app_routes.dart';


class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final GlobalKey<MarketplacePageState> _marketplaceKey =
      GlobalKey<MarketplacePageState>();
  final GlobalKey<SearchPageState> _searchKey =
      GlobalKey<SearchPageState>();
  final GlobalKey<CommunityPageState> _communityKey =
    GlobalKey<CommunityPageState>();
  final GlobalKey<ProfilePageState> _profileKey =
      GlobalKey<ProfilePageState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      MarketplacePage(key: _marketplaceKey),
      SearchPage(key: _searchKey),
      SellPage(
        onProductUploaded: () {
          _onTabSelected(0);
        },
      ),
      CommunityPage(key: _communityKey),
      ProfilePage(key: _profileKey),
    ];
    // Ensure user info is loaded when the main shell first mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserViewModel>();
      if (userProvider.profile == null && !userProvider.isLoading) {
        userProvider.load();
      }

      final chatProvider = context.read<ChatRoomViewModel>();
      chatProvider.setCurrentUserId(userProvider.userId);
      if (chatProvider.conversations.isEmpty && !chatProvider.isLoadingConversations) {
        chatProvider.loadConversations(refresh: true);
      }
    });
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      _handleTabReselected(index);
      return;
    }

    final fromIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });

    const contentTabs = {2, 3};
    if (index == 4 && contentTabs.contains(fromIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profileKey.currentState?.refresh();
      });
    }
  }

  void _handleTabReselected(int index) {
    switch (index) {
      case 0:
        _marketplaceKey.currentState?.scrollToTopAndRefresh();
        break;
      case 1:
        _searchKey.currentState?.scrollToTopAndRefresh();
        break;
      case 3:
        _communityKey.currentState?.scrollToTopAndRefresh();
        break;
      case 4:
        _profileKey.currentState?.refresh();
        break;
    }
  }

  PreferredSizeWidget _buildAppBar(int chatBadgeCount, int pendingPurchaseBadgeCount) {
    return AppAppBar(
      chatBadgeCount: chatBadgeCount,
      pendingPurchaseBadgeCount: pendingPurchaseBadgeCount,
      onFavoriteTap: () {
        Navigator.pushNamed(context, AppRoutes.saved);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatBadgeCount = context.select<ChatRoomViewModel, int>(
      (viewModel) => viewModel.totalUnreadCount,
    );
    final pendingPurchaseBadgeCount = context.select<ChatRoomViewModel, int>(
      (viewModel) => viewModel.pendingPurchaseCount,
    );

    // Keep currentUserId in sync when profile loads
    final userId = context.select<UserViewModel, int?>(
      (vm) => vm.userId,
    );
    if (userId != null) {
      context.read<ChatRoomViewModel>().setCurrentUserId(userId);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(chatBadgeCount, pendingPurchaseBadgeCount),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
