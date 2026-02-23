import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../models/category.dart';

class CategoryCircle extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const CategoryCircle({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 15,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 3 : 2,
                ),
                color: AppColors.surface,
              ),
              child: ClipOval(
                child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                    ? Image.network(
                        category.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: size * 0.4,
                        ),
                      )
                    : Icon(
                        Icons.category,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: size * 0.4,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class SeeAllCircle extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const SeeAllCircle({
    super.key,
    this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 15,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                color: AppColors.primary,
                size: size * 0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'See All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrollable list of category circles with optional "See All" button
class CategoryList extends StatelessWidget {
  final List<Category> categories;
  final int? selectedIndex;
  final ValueChanged<int?>? onCategorySelected;
  final VoidCallback? onSeeAllTap;
  final double height;
  final double circleSize;
  final bool showSeeAll;

  const CategoryList({
    super.key,
    required this.categories,
    this.selectedIndex,
    this.onCategorySelected,
    this.onSeeAllTap,
    this.height = 110,
    this.circleSize = 70,
    this.showSeeAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length + (showSeeAll ? 1 : 0),
        itemBuilder: (context, index) {
          if (showSeeAll && index == categories.length) {
            return SeeAllCircle(size: circleSize, onTap: onSeeAllTap);
          }
          return CategoryCircle(
            category: categories[index],
            isSelected: selectedIndex == index,
            size: circleSize,
            onTap: () {
              onCategorySelected?.call(selectedIndex == index ? null : index);
            },
          );
        },
      ),
    );
  }
}