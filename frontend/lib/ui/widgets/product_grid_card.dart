import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../domain/entities/product_entity.dart';

/// Grid card for displaying products in a grid layout
class ProductGridCard extends StatelessWidget {
  final ProductEntity product;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onLongPress;
  final IconData? actionIcon;
  final Color? actionIconColor;

  const ProductGridCard({
    super.key,
    required this.product,
    this.isLiked = false,
    this.onTap,
    this.onLikeTap,
    this.onLongPress,
    this.actionIcon,
    this.actionIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final firstImageUrl = product.firstImageUrl;
    final isNetworkImage = (firstImageUrl?.startsWith('http://') ?? false) ||
        (firstImageUrl?.startsWith('https://') ?? false);

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
                color: Colors.black.withValues(alpha: 0.05),
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
                      child: RepaintBoundary(
                        child: Container(
                          width: double.infinity,
                          color: AppColors.surface,
                          child: firstImageUrl == null
                              ? Container(
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.image,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : isNetworkImage
                                  ? CachedNetworkImage(
                                  key: ValueKey('grid_image_${product.id}_$firstImageUrl'),
                                  imageUrl: firstImageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  useOldImageOnUrlChange: true,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.surface,
                                    child: const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.surface,
                                    child: const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                                  : Image.asset(
                                      firstImageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: AppColors.surface,
                                        child: const Icon(
                                          Icons.image,
                                          size: 40,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
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
                    iconOverride: actionIcon,
                    iconOverrideColor: actionIconColor,
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
  final IconData? iconOverride;
  final Color? iconOverrideColor;

  const LikeButton({
    super.key,
    this.isLiked = false,
    this.onTap,
    this.size = 36,
    this.iconOverride,
    this.iconOverrideColor,
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
            color: AppColors.background.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconOverride ?? (isLiked ? Icons.favorite : Icons.favorite_border),
            color: iconOverrideColor ?? (isLiked ? Colors.red : AppColors.textSecondary),
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}
