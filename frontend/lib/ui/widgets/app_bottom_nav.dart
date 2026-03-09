import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const AppBottomNav({
    super.key,
    this.currentIndex = 0,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Marketplace',
                  index: 0,
                ), 
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  index: 1,
                ),
              ),
              Expanded(
                child: _buildCenterButton(context),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.groups_rounded,
                  label: 'Community',
                  index: 3,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  index: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        if (isSelected) {
          if (index == 0) {
            onTabSelected?.call(index);
          }
          return;
        }

        onTabSelected?.call(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    final isSelected = currentIndex == 2;
    const activeColor = AppColors.primary;
    const inactiveLabelColor = AppColors.textSecondary;
    const inactiveBgColor = AppColors.accent;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    
    return InkWell(
      onTap: () {
        if (!isSelected) {
          onTabSelected?.call(2);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : inactiveBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                color: isSelected ? onPrimary : activeColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Sell Now',
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveLabelColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}