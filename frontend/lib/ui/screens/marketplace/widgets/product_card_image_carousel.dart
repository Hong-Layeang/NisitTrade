import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';

class ProductCardImageCarousel extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Key? pageViewKey;

  const ProductCardImageCarousel({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    this.pageViewKey,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.surface,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Main carousel
        PageView.builder(
          key: pageViewKey,
          controller: pageController,
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            final imageUrl = images[index];
            final isNetwork =
                imageUrl.startsWith('http://') ||
                imageUrl.startsWith('https://');

            if (isNetwork) {
              return CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                useOldImageOnUrlChange: true,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.image,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surface,
                child: const Icon(
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
              children: List.generate(images.length > 8 ? 8 : images.length, (
                index,
              ) {
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
              }),
            ),
          ),
      ],
    );
  }
}
