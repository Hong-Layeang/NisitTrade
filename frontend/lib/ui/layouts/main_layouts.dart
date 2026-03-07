import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../widgets/app_bottom_nav.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int currentNavIndex;
  final bool showAppBar;
  final PreferredSizeWidget? appBar;

  const MainLayout({
    super.key,
    required this.child,
    this.currentNavIndex = 0,
    this.showAppBar = false,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: child,
      bottomNavigationBar: AppBottomNav(currentIndex: currentNavIndex),
    );
  }
}