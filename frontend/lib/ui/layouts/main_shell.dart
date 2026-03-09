import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../logic/view_models/user_view_model.dart';
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
  final GlobalKey<ProfilePageState> _profileKey =
      GlobalKey<ProfilePageState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      MarketplacePage(key: _marketplaceKey),
      const SearchPage(),
      const SellPage(),
      const CommunityPage(),
      ProfilePage(key: _profileKey),
    ];
    // Ensure user info is loaded when the main shell first mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserViewModel>();
      if (userProvider.profile == null && !userProvider.isLoading) {
        userProvider.load();
      }
    });
  }

  void _onTabSelected(int index) {
    final shouldSwitch = _currentIndex != index;

    if (shouldSwitch) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppAppBar(
      chatBadgeCount: 6,
      onFavoriteTap: () {
        Navigator.pushNamed(context, AppRoutes.saved);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
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
