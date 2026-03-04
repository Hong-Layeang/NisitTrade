import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../screens/community/community_page.dart';
import '../screens/marketplace/marketplace_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/search/search_page.dart';
import '../Screens/sell/sell_page.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_bottom_nav.dart';
import '../../utils/routes/app_routes.dart';


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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    final shouldSwitch = _currentIndex != index;

    if (shouldSwitch) {
      setState(() {
        _currentIndex = index;
      });
      // Refresh profile data from server whenever the profile tab is (re)selected.
      if (index == 4) {
        _profileKey.currentState?.refresh();
      }
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
        children: [
          MarketplacePage(key: _marketplaceKey),
          const SearchPage(),
          const SellPage(),
          const CommunityPage(),
          ProfilePage(key: _profileKey),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}