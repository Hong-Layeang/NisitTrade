import 'package:flutter/material.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/constants/colors.dart';
import 'category_widgets.dart';

/// Filter strip for selecting categories with animation
class CategoryFilterStrip extends StatelessWidget {
  final List<CategoryEntity> categories;
  final int? selectedIndex;
  final ValueChanged<int?> onCategorySelected;
  final bool isOpen;
  final VoidCallback onToggle;

  const CategoryFilterStrip({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIndex != null;
    final labelText = hasSelection ? categories[selectedIndex!].name : 'All Categories';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle ro
        Material(
          color: AppColors.background,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 17,
                    color: (isOpen || hasSelection)
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (isOpen || hasSelection)
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 1,
                    height: 12,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasSelection
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: hasSelection
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Clear button when a category is selected
                  if (hasSelection)
                    GestureDetector(
                      onTap: () => onCategorySelected(null),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4, right: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Icon(
                    isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Slide-down category panel
        ClipRect(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            height: isOpen ? 84.0 : 0.0,
            color: AppColors.background,
            child: OverflowBox(
              maxHeight: 84.0,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 84,
                child: CategoryList(
                  categories: categories,
                  selectedIndex: selectedIndex,
                  onCategorySelected: onCategorySelected,
                  onSeeAllTap: () {},
                  showSeeAll: false,
                  height: 84,
                  circleSize: 52,
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
      ],
    );
  }
}
