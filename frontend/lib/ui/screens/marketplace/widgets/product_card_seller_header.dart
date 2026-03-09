import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../logic/view_models/user_view_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../widgets/user_widgets.dart';

/// Displays the seller information in a product card.
class ProductCardSellerHeader extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onMoreTap;
  final VoidCallback? onSellerTap;

  const ProductCardSellerHeader({
    super.key,
    required this.product,
    this.onMoreTap,
    this.onSellerTap,
  });

  String _extractUniversity(String email) {
    final parts = email.split('@');
    if (parts.length < 2) return email;
    
    final domainParts = parts[1].split('.');
    if (domainParts.length >= 2) {
      return '@${domainParts[1]}';
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when userId or profileImage changes
    // This prevents unnecessary rebuilds when other UserViewModel properties change
    return Selector<UserViewModel, ({int? userId, String? profileImage})>(
      selector: (_, vm) => (
        userId: vm.userId,
        profileImage: vm.profile?.profileImage,
      ),
      builder: (context, userData, _) {
        final isCurrentUser = userData.userId != null &&
            product.userId == userData.userId;
        final avatarUrl = isCurrentUser
            ? userData.profileImage
            : product.seller?.profileImage;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onSellerTap,
                child: Row(
                  children: [
                    RepaintBoundary(
                      child: UserAvatar(
                        key: ValueKey('seller_avatar_${product.userId}_${avatarUrl ?? "default"}'),
                        imageUrl: avatarUrl ?? 'https://i.pravatar.cc/300?img=99',
                        radius: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.seller?.fullName ?? 'Unknown Seller',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _extractUniversity(product.seller?.email ?? 'Unknown'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onMoreTap,
                icon: const Icon(Icons.more_vert),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }
}

