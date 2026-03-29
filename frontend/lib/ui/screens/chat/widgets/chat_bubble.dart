import 'package:flutter/material.dart';

import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/utils/chat_timestamp_formatter.dart';
import 'package:frontend/core/utils/image_url_helper.dart';
import 'package:frontend/data/dtos/conversation_dto.dart';
import 'package:frontend/data/dtos/product_dto.dart';
import 'package:frontend/ui/screens/chat/purchase_confirmation_message.dart';
import 'package:frontend/ui/widgets/full_screen_image_viewer.dart';
import 'package:frontend/ui/widgets/s3_cached_network_image.dart';

class ChatBubble extends StatelessWidget {
  final MessageDto message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final ProductDto? attachedProduct;
  final bool showAttachedProductCard;
  final bool isSelected;
  final bool isSelectionMode;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.onTap,
    this.attachedProduct,
    this.showAttachedProductCard = true,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessageText = PurchaseConfirmationMessage.isPurchaseConfirmation(
          message.messageText,
        )
        ? PurchaseConfirmationMessage.displayText(
            productTitle: attachedProduct?.title,
          )
        : message.messageText;
    final textColor = isCurrentUser ? Colors.white : AppColors.textPrimary;
    final hasMessageText = displayMessageText.trim().isNotEmpty;
    final imageUrls = message.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .map(ImageUrlHelper.getFullImageUrl)
        .where(ImageUrlHelper.isValidUrl)
        .toList(growable: false);
    final hasImages = imageUrls.isNotEmpty;
    final bubblePadding = hasImages
        ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
        : const EdgeInsets.fromLTRB(14, 11, 14, 9);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: isSelectionMode ? onTap : null,
          child: Container(
            margin: EdgeInsets.only(
              left: isCurrentUser ? 52 : (isSelectionMode ? 0 : 12),
              right: isCurrentUser ? 12 : 52,
              top: 5,
              bottom: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (isSelectionMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                Flexible(
                  child: _buildBubbleContent(
                    context,
                    bubblePadding: bubblePadding,
                    displayMessageText: displayMessageText,
                    textColor: textColor,
                    hasMessageText: hasMessageText,
                    hasImages: hasImages,
                    imageUrls: imageUrls,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent(
    BuildContext context, {
    required EdgeInsets bubblePadding,
    required String displayMessageText,
    required Color textColor,
    required bool hasMessageText,
    required bool hasImages,
    required List<String> imageUrls,
  }) {
    final container = Container(
      padding: bubblePadding,
      decoration: _buildBubbleDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showAttachedProductCard && attachedProduct != null) ...[
            _buildAttachedProduct(context),
            if (hasMessageText || imageUrls.isNotEmpty)
              const SizedBox(height: 8),
          ],
          if (imageUrls.isNotEmpty) ...[
            _buildImageGallery(context, imageUrls),
            if (hasMessageText) const SizedBox(height: 8),
          ],
          if (hasMessageText)
            SelectableText(
              displayMessageText,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          SizedBox(height: hasMessageText ? 2 : 4),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isEdited) ...[
                  Text(
                    'edited',
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  formatChatTimestamp(message.sentAt),
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.white.withValues(alpha: 0.78)
                        : AppColors.textSecondary.withValues(alpha: 0.92),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  _buildReadStatus(),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (hasImages) return container;
    return IntrinsicWidth(child: container);
  }

  BoxDecoration _buildBubbleDecoration() {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isCurrentUser ? 20 : 8),
      bottomRight: Radius.circular(isCurrentUser ? 8 : 20),
    );

    if (isCurrentUser) {
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18A4DF), Color(0xFF008DCF)],
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008DCF).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: const Color(0xFFFBFDFF),
      borderRadius: borderRadius,
      border: Border.all(color: const Color(0xFFD9E6EE)),
      boxShadow: [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildReadStatus() {
    if (message.readBy.isEmpty) {
      return const Icon(Icons.done_rounded, size: 13, color: Colors.white70);
    }
    return const Icon(
      Icons.done_all_rounded,
      size: 13,
      color: Color(0xFFB9F0FF),
    );
  }

  Widget _buildImageGallery(BuildContext context, List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final singleImageHeight =
              (constraints.maxWidth * 1.08).clamp(180.0, 340.0).toDouble();

          return _buildImageTile(
            context,
            imageUrls: imageUrls,
            imageUrl: imageUrls.first,
            index: 0,
            width: constraints.maxWidth,
            height: singleImageHeight,
            fit: BoxFit.cover,
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final visibleCount = imageUrls.length.clamp(0, 4);
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        final tileHeight = tileWidth * 1.02;

        if (visibleCount == 2) {
          return Row(
            children: [
              _buildImageTile(
                context,
                imageUrls: imageUrls,
                imageUrl: imageUrls[0],
                index: 0,
                width: tileWidth,
                height: tileHeight,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: spacing),
              _buildImageTile(
                context,
                imageUrls: imageUrls,
                imageUrl: imageUrls[1],
                index: 1,
                width: tileWidth,
                height: tileHeight,
                fit: BoxFit.cover,
              ),
            ],
          );
        }

        if (visibleCount == 3) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildImageTile(
                    context,
                    imageUrls: imageUrls,
                    imageUrl: imageUrls[0],
                    index: 0,
                    width: tileWidth,
                    height: tileHeight,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: spacing),
                  _buildImageTile(
                    context,
                    imageUrls: imageUrls,
                    imageUrl: imageUrls[1],
                    index: 1,
                    width: tileWidth,
                    height: tileHeight,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
              const SizedBox(height: spacing),
              _buildImageTile(
                context,
                imageUrls: imageUrls,
                imageUrl: imageUrls[2],
                index: 2,
                width: constraints.maxWidth,
                height: tileHeight,
                fit: BoxFit.cover,
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildImageTile(
                  context,
                  imageUrls: imageUrls,
                  imageUrl: imageUrls[0],
                  index: 0,
                  width: tileWidth,
                  height: tileHeight,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: spacing),
                _buildImageTile(
                  context,
                  imageUrls: imageUrls,
                  imageUrl: imageUrls[1],
                  index: 1,
                  width: tileWidth,
                  height: tileHeight,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            const SizedBox(height: spacing),
            Row(
              children: [
                _buildImageTile(
                  context,
                  imageUrls: imageUrls,
                  imageUrl: imageUrls[2],
                  index: 2,
                  width: tileWidth,
                  height: tileHeight,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: spacing),
                _buildImageTile(
                  context,
                  imageUrls: imageUrls,
                  imageUrl: imageUrls[3],
                  index: 3,
                  width: tileWidth,
                  height: tileHeight,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageTile(
    BuildContext context, {
    required List<String> imageUrls,
    required String imageUrl,
    required int index,
    double? width,
    double? height,
    double? maxWidth,
    double? maxHeight,
    BoxFit fit = BoxFit.contain,
  }) {
    final s3Key = ImageUrlHelper.extractS3KeyFromUrl(imageUrl) ?? imageUrl;
    final image = S3CachedNetworkImage(
      imageUrl: imageUrl,
      s3Key: s3Key,
      width: width,
      height: height,
      fit: fit,
    );

    return GestureDetector(
      onTap: () => FullScreenImageViewer.show(
        context,
        imageUrl,
        allImages: imageUrls,
        initialIndex: index,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: maxWidth != null || maxHeight != null
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth ?? double.infinity,
                  maxHeight: maxHeight ?? double.infinity,
                ),
                child: image,
              )
            : image,
      ),
    );
  }

  Widget _buildAttachedProduct(BuildContext context) {
    final imageUrl = attachedProduct?.firstImageUrl?.trim();
    final s3Key = imageUrl != null && imageUrl.isNotEmpty
        ? ImageUrlHelper.extractS3KeyFromUrl(imageUrl) ?? imageUrl
        : null;
    final resolvedImageUrl = imageUrl != null && imageUrl.isNotEmpty
        ? ImageUrlHelper.getFullImageUrl(imageUrl)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.white.withValues(alpha: 0.14)
            : const Color(0xFFF2F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFDCE8F0),
        ),
      ),
      padding: const EdgeInsets.all(9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: resolvedImageUrl != null
                ? S3CachedNetworkImage(
                    imageUrl: resolvedImageUrl,
                    s3Key: s3Key,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: Colors.white30,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachedProduct?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  attachedProduct?.formattedPrice ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser ? Colors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

