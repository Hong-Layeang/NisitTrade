import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../utils/constants/colors.dart';
import '../common/user_widgets.dart';

class ProductCardSellerHeader extends StatelessWidget {
  final Product product;
  final VoidCallback? onMoreTap;

  const ProductCardSellerHeader({
    super.key,
    required this.product,
    this.onMoreTap,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: product.sellerProfileImage ?? 'https://i.pravatar.cc/300?img=99',
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
          ),
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
