import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/utils/image_url_helper.dart';
import 'package:frontend/data/models/conversation.dart';
import 'package:frontend/data/models/product.dart';
import 'package:frontend/ui/widgets/full_screen_image_viewer.dart';
import 'package:frontend/ui/widgets/s3_cached_network_image.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final Product? attachedProduct;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.attachedProduct,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser ? const Color(0xFF1298D6) : Colors.white;
    final textColor = isCurrentUser ? Colors.white : AppColors.textPrimary;
    final imageUrls = message.imageUrls
        .map(ImageUrlHelper.getFullImageUrl)
        .toList(growable: false);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: EdgeInsets.only(
              left: isCurrentUser ? 52 : 12,
              right: isCurrentUser ? 12 : 52,
              top: 5,
              bottom: 5,
            ),
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isCurrentUser ? 22 : 8),
                bottomRight: Radius.circular(isCurrentUser ? 8 : 22),
              ),
              border: isCurrentUser
                  ? null
                  : Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attachedProduct != null) ...[
                  _buildAttachedProduct(context),
                  if (message.messageText.trim().isNotEmpty || imageUrls.isNotEmpty)
                    const SizedBox(height: 10),
                ],
                if (imageUrls.isNotEmpty) ...[
                  _buildImageGallery(context, imageUrls),
                  if (message.messageText.trim().isNotEmpty) const SizedBox(height: 10),
                ],
                if (message.messageText.trim().isNotEmpty)
                  Text(
                    message.messageText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Timeago(
                      date: message.sentAt,
                      builder: (context, value) => Text(
                        value,
                        style: TextStyle(
                          color: isCurrentUser
                              ? Colors.white.withValues(alpha: 0.84)
                              : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      _buildReadStatus(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadStatus() {
    if (message.readBy.isEmpty) {
      return const Icon(Icons.done_rounded, size: 14, color: Colors.white70);
    }
    return const Icon(Icons.done_all_rounded, size: 14, color: Colors.lightBlueAccent);
  }

  Widget _buildImageGallery(BuildContext context, List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return _buildImageTile(
        context,
        imageUrls: imageUrls,
        imageUrl: imageUrls.first,
        index: 0,
        height: 220,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List<Widget>.generate(
        imageUrls.length.clamp(0, 4),
        (index) => _buildImageTile(
          context,
          imageUrls: imageUrls,
          imageUrl: imageUrls[index],
          index: index,
          width: imageUrls.length == 2 ? 120 : 98,
          height: imageUrls.length == 2 ? 140 : 98,
        ),
      ),
    );
  }

  Widget _buildImageTile(
    BuildContext context, {
    required List<String> imageUrls,
    required String imageUrl,
    required int index,
    double? width,
    double? height,
  }) {
    final s3Key = ImageUrlHelper.extractS3KeyFromUrl(imageUrl) ?? imageUrl;

    return GestureDetector(
      onTap: () => FullScreenImageViewer.show(
        context,
        imageUrl,
        allImages: imageUrls,
        initialIndex: index,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: S3CachedNetworkImage(
          imageUrl: imageUrl,
          s3Key: s3Key,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
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
            ? Colors.white.withValues(alpha: 0.16)
            : const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
