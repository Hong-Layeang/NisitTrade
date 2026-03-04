import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../models/product.dart';

class ProductGridCard extends StatelessWidget {
  final Product product;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onLongPress;

  const ProductGridCard({
    super.key,
    required this.product,
    this.isLiked = false,
    this.onTap,
    this.onLikeTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: AppColors.surface,
                        child: product.firstImageUrl != null
                            ? Image.network(
                                product.firstImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: AppColors.surface,
                                  child: Icon(
                                    Icons.image,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.surface,
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: LikeButton(
                    isLiked: isLiked,
                    onTap: onLikeTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable like/favorite button
class LikeButton extends StatelessWidget {
  final bool isLiked;
  final VoidCallback? onTap;
  final double size;

  const LikeButton({
    super.key,
    this.isLiked = false,
    this.onTap,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : AppColors.textSecondary,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}
