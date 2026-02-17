import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../widgets/profile/profile_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTabIndex = 0;

  // ── Mock profile data ──
  static const _coverImageUrl =
      'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800';
  static const _avatarUrl = 'https://i.pravatar.cc/300?img=12';
  static const _name = 'John Smith';
  static const _bio =
      "Without Coffee life equals zero, so don't forget to drink coffee";
  static const _institution = 'CADT';
  static const _role = 'Software\nEnginner';
  static const _friendsCount = '13k';
  static const _itemsSold = '10';

  static const _productImages = [
    'assets/images/products/lightGreenBackpack.png',
    'assets/images/products/airpods.png',
    'assets/images/products/gamingMouse.png',
    'assets/images/products/keyboard.png',
    'assets/images/products/gamingLaptop.png',
    'assets/images/products/smartPhone.png',
  ];

  // ── Layout constants ──
  static const double _coverHeight = 280;
  static const double _avatarRadius = 65;
  static const double _avatarBorder = 3;
  static const double _avatarGap = 3;
  static const double _avatarTotalRadius =
      _avatarRadius + _avatarGap + _avatarBorder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCoverAndAvatar(),
          _buildStatsRow(),
          _buildNameAndBio(textTheme),
          const SizedBox(height: 16),
          ProfileSectionTabBar(
            selectedIndex: _selectedTabIndex,
            onTabChanged: (i) => setState(() => _selectedTabIndex = i),
          ),
          _buildProductGrid(),
        ],
      ),
    );
  }

  /// Cover image with overlapping avatar and three-dot menu
  Widget _buildCoverAndAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image
        SizedBox(
          height: _coverHeight,
          width: double.infinity,
          child: Image.network(
            _coverImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.accent.withOpacity(0.3),
              child: const Icon(Icons.image, size: 48, color: Colors.white54),
            ),
          ),
        ),
        // Three-dot menu
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        // Profile avatar overlapping bottom of cover
        Positioned(
          bottom: -_avatarTotalRadius,
          left: 0,
          right: 0,
          child: Center(
            child: ProfileAvatar(
              imageUrl: _avatarUrl,
              radius: _avatarRadius,
              borderWidth: _avatarBorder,
              gapWidth: _avatarGap,
            ),
          ),
        ),
      ],
    );
  }

  /// Stats flanking the avatar overlap area
  Widget _buildStatsRow() {
    return SizedBox(
      height: _avatarTotalRadius + 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left stats
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ProfileStatItem(
                    icon: Icons.people_outline,
                    value: _friendsCount,
                    label: 'Friends',
                  ),
                  SizedBox(height: 6),
                  ProfileStatItem(
                    icon: Icons.shopping_cart_outlined,
                    value: _itemsSold,
                    label: 'items sold',
                  ),
                ],
              ),
            ),
            // Center gap for avatar
            SizedBox(width: _avatarTotalRadius * 2),
            // Right stats
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  ProfileStatItem(
                    icon: Icons.inventory_2_outlined,
                    value: _institution,
                  ),
                  SizedBox(height: 6),
                  ProfileStatItem(
                    icon: Icons.verified_outlined,
                    value: _role,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile name and bio text
  Widget _buildNameAndBio(TextTheme textTheme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _name,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _bio,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// 3-column product image grid
  Widget _buildProductGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _productImages.length,
      itemBuilder: (context, index) {
        return Image.asset(
          _productImages[index],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surface,
            child: const Icon(Icons.image, color: AppColors.textSecondary),
          ),
        );
      },
    );
  }
}
