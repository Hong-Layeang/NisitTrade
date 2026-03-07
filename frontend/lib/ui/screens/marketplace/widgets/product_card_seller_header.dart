import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/product.dart';
import '../../../../logic/view_models/user_view_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../widgets/user_widgets.dart';

class ProductCardSellerHeader extends StatelessWidget {
  final Product product;
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
    // If this product belongs to the current user, use the live profile image
    // from UserViewModel so avatar updates are reflected immediately without
    // waiting for the product feed to be re-fetched.
    final userProvider = context.watch<UserViewModel>();
    final isCurrentUser = userProvider.userId != null &&
        product.userId == userProvider.userId;
    final avatarUrl = isCurrentUser
        ? userProvider.profile?.profileImage
        : product.sellerProfileImage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onSellerTap,
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: avatarUrl ?? 'https://i.pravatar.cc/300?img=99',
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sellerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _extractUniversity(product.user?.email ?? 'Unknown'),
                      style: TextStyle(
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
  }
}

