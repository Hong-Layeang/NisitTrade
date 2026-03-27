import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../data/dtos/category_dto.dart';

class CategoryCircle extends StatelessWidget {
  final CategoryDto category;
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
                    ? RepaintBoundary(
                        child: CachedNetworkImage(
                          key: ValueKey('category_${category.id}_${category.imageUrl}'),
                          imageUrl: category.imageUrl!,
                          fit: BoxFit.cover,
                          useOldImageOnUrlChange: true,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (context, url) => Container(
                            color: AppColors.surface,
                            child: Icon(
                              Icons.category,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              size: size * 0.4,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.category,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            size: size * 0.4,
                          ),
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

class SeeLessCircle extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const SeeLessCircle({
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
                  color: AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.expand_less_rounded,
                color: AppColors.textSecondary,
                size: size * 0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'See Less',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrollable list of category circles with optional "See All" / "See Less" button
class CategoryList extends StatelessWidget {
  final List<CategoryDto> categories;
  final int? selectedIndex;
  final ValueChanged<int?>? onCategorySelected;
  final VoidCallback? onSeeAllTap;
  final VoidCallback? onSeeLessTap;
  final double height;
  final double circleSize;
  final bool showSeeAll;
  final bool showSeeLess;

  const CategoryList({
    super.key,
    required this.categories,
    this.selectedIndex,
    this.onCategorySelected,
    this.onSeeAllTap,
    this.onSeeLessTap,
    this.height = 110,
    this.circleSize = 70,
    this.showSeeAll = true,
    this.showSeeLess = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasExtra = showSeeAll || showSeeLess;
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length + (hasExtra ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasExtra && index == categories.length) {
            if (showSeeLess) {
              return SeeLessCircle(size: circleSize, onTap: onSeeLessTap);
            }
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
