import 'package:flutter/material.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../widgets/app_action_chip.dart';

/// Displays action row with like, comment, chat buttons
class ProductCardActionRow extends StatelessWidget {
  final ProductEntity product;
  final bool isLiked;
  final bool isLoading;
  final AnimationController likeAnimationController;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onChatTap;

  const ProductCardActionRow({
    super.key,
    required this.product,
    required this.isLiked,
    this.isLoading = false,
    required this.likeAnimationController,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          AppActionChip(
            icon: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.25).animate(
                CurvedAnimation(
                  parent: likeAnimationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : AppColors.textPrimary,
                size: 18,
              ),
            ),
            label: NumberFormatters.formatCount(product.likesCount),
            labelColor: isLiked ? Colors.red : AppColors.textPrimary,
            onTap: onLikeTap,
          ),
          const SizedBox(width: 4),
          AppActionChip(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textPrimary,
              size: 18,
            ),
            label: NumberFormatters.formatCount(product.commentsCount),
            labelColor: AppColors.textPrimary,
            onTap: onCommentTap,
          ),
          const Spacer(),
          // Price badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '💰',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 3),
                Text(
                  NumberFormatters.formatPrice(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Chat button
          InkWell(
            onTap: onChatTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}