import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/image_url_helper.dart';
import '../../../../data/dtos/product_dto.dart';
import '../../../../logic/view_models/chat_view_model.dart';
import '../../../../ui/widgets/s3_cached_network_image.dart';

class AttachmentCarousel extends StatefulWidget {
  final List<AttachedProduct> attachedProducts;
  final String Function(AttachedProduct ap) countdownLabelBuilder;
  final bool Function(AttachedProduct ap) isExpiredBuilder;
  final bool Function(ProductDto product) isOwnerBuilder;
  final void Function(ProductDto product) onTapProduct;
  final void Function(ProductDto product) onConfirmPurchase;
  final void Function(ProductDto product) onMarkAsSold;
  final void Function(ProductDto product) onRemove;

  const AttachmentCarousel({
    super.key,
    required this.attachedProducts,
    required this.countdownLabelBuilder,
    required this.isExpiredBuilder,
    required this.isOwnerBuilder,
    required this.onTapProduct,
    required this.onConfirmPurchase,
    required this.onMarkAsSold,
    required this.onRemove,
  });

  @override
  State<AttachmentCarousel> createState() => _AttachmentCarouselState();
}

class _AttachmentCarouselState extends State<AttachmentCarousel> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant AttachmentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.attachedProducts.length && widget.attachedProducts.isNotEmpty) {
      _currentPage = widget.attachedProducts.length - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmRemove(ProductDto product, {required bool isOwner}) async {
    final title = isOwner ? 'Remove Sale Tracking' : 'Cancel Purchase';
    final body = isOwner
        ? 'Stop tracking this sale for "${product.title}"?'
        : 'Are you sure you want to remove "${product.title}" from your purchase list?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD64545)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onRemove(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachedProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 164,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.attachedProducts.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final ap = widget.attachedProducts[index];
              final isOwner = widget.isOwnerBuilder(ap.product);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: _AttachmentCard(
                  product: ap.product,
                  countdownLabel: widget.countdownLabelBuilder(ap),
                  isExpired: widget.isExpiredBuilder(ap),
                  isOwner: isOwner,
                  onTap: () => widget.onTapProduct(ap.product),
                  onConfirmPurchase: () => widget.onConfirmPurchase(ap.product),
                  onMarkAsSold: () => widget.onMarkAsSold(ap.product),
                  onRemove: () => _confirmRemove(ap.product, isOwner: isOwner),
                ),
              );
            },
          ),
        ),
        if (widget.attachedProducts.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.attachedProducts.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final ProductDto product;
  final String countdownLabel;
  final bool isExpired;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onConfirmPurchase;
  final VoidCallback onMarkAsSold;
  final VoidCallback onRemove;

  const _AttachmentCard({
    required this.product,
    required this.countdownLabel,
    required this.isExpired,
    required this.isOwner,
    required this.onTap,
    required this.onConfirmPurchase,
    required this.onMarkAsSold,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.firstImageUrl?.trim();
    final s3Key = imageUrl != null && imageUrl.isNotEmpty
        ? ImageUrlHelper.extractS3KeyFromUrl(imageUrl) ?? imageUrl
        : null;
    final resolvedImageUrl = imageUrl != null && imageUrl.isNotEmpty
        ? ImageUrlHelper.getFullImageUrl(imageUrl)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product image with styled background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: resolvedImageUrl != null
                            ? S3CachedNetworkImage(
                                imageUrl: resolvedImageUrl,
                                s3Key: s3Key,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 28,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.formattedPrice,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Countdown / status label
                            if (isOwner)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Your Listing',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      countdownLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isExpired
                                            ? const Color(0xFFD64545)
                                            : const Color(0xFFE67E22),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Icon(
                                    isExpired
                                        ? Icons.timer_off_rounded
                                        : Icons.timer_outlined,
                                    size: 13,
                                    color: isExpired
                                        ? const Color(0xFFD64545)
                                        : const Color(0xFFE67E22),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      countdownLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isExpired
                                            ? const Color(0xFFD64545)
                                            : const Color(0xFFE67E22),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: isOwner
                      ? onMarkAsSold
                      : (isExpired ? null : onConfirmPurchase),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwner
                        ? const Color(0xFF0FBA81)
                        : AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(
                    isOwner
                        ? 'Mark as Sold'
                        : (isExpired ? 'Expired' : 'Confirm Purchase'),
                  ),
                ),
              ),
            ],
          ),
        ),
        // X button to remove
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, size: 14, color: Colors.black54),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

