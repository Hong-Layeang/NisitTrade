import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../screens/community/community_page.dart';
import '../screens/marketplace/marketplace_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/search/search_page.dart';
import '../Screens/sell/sell_page.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return const AppAppBar(chatBadgeCount: 6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MarketplacePage(),
          const SearchPage(),
          const SellPage(),
          const CommunityPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}