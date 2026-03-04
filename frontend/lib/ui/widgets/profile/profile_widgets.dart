import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? displayName;
  final double radius;
  final double borderWidth;
  final double gapWidth;
  final Color borderColor;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.radius = 65,
    this.borderWidth = 3,
    this.gapWidth = 3,
    this.borderColor = AppColors.accent,
  });

  /// Total visual radius including gap and border
  double get totalRadius => radius + gapWidth + borderWidth;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _imageError = false;

  String _initials() {
    final name = widget.displayName?.trim() ?? '';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() => _imageError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = !_imageError &&
        widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(widget.gapWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(color: widget.borderColor, width: widget.borderWidth),
      ),
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.primary.withOpacity(0.15),
        backgroundImage: hasImage ? NetworkImage(widget.imageUrl!) : null,
        onBackgroundImageError: hasImage
            ? (_, __) => setState(() => _imageError = true)
            : null,
        child: !hasImage
            ? Text(
                _initials(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: widget.radius * 0.42,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Icon-only tab bar
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
