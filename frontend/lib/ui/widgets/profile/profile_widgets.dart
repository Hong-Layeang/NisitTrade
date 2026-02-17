import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

/// Circular profile avatar with a colored border ring and white gap.
/// Extends the pattern from [UserAvatar] with an outer ring decoration.
class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final double borderWidth;
  final double gapWidth;
  final Color borderColor;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 65,
    this.borderWidth = 3,
    this.gapWidth = 3,
    this.borderColor = AppColors.accent,
  });

  /// Total visual radius including gap and border
  double get totalRadius => radius + gapWidth + borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(gapWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
        child: Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: radius,
        ),
      ),
    );
  }
}

/// Reusable stat row: icon + highlighted value + optional plain label.
/// Used for profile metrics like "13k Friends" or "CADT".
class ProfileStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;

  const ProfileStatItem({
    super.key,
    required this.icon,
    required this.value,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (label != null)
                  TextSpan(
                    text: ' $label',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon-only tab bar for switching between profile content sections.
class ProfileSectionTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const ProfileSectionTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTab(icon: Icons.post_add_outlined, index: 0),
        _buildTab(icon: Icons.perm_contact_cal_outlined, index: 1),
      ],
    );
  }

  Widget _buildTab({required IconData icon, required int index}) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2.5 : 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
