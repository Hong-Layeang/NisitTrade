import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../core/constants/colors.dart';

/// Displays product information in the product card
class ProductCardInfo extends StatelessWidget {
  final ProductEntity product;

  const ProductCardInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.description ?? 'No description',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Timeago(
            date: product.createdAt,
            builder: (context, value) => Text(
              value,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
