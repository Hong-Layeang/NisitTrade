import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

class ProductCardImageCarousel extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const ProductCardImageCarousel({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder( // main carousel
          controller: pageController,
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return Image.asset(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surface,
                child: Icon(
                  Icons.image,
                  size: 80,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          },
        ),
        // Image counter badge (top-right corner)
        if (images.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentIndex + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Page indicators (dots at bottom)
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length > 8 ? 8 : images.length,
                (index) {
                  int displayIndex = index;
                  if (images.length > 8 && currentIndex > 3) {
                    displayIndex = currentIndex - 3 + index;
                    if (displayIndex >= images.length) {
                      displayIndex = images.length - 8 + index;
                    }
                  }
                  final isActive = displayIndex == currentIndex;
                  return Container(
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
