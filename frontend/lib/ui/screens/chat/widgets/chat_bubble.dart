import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:frontend/data/models/conversation.dart';
import 'package:frontend/data/models/product.dart';

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
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (attachedProduct != null) ...[
                _buildAttachedProduct(context),
                const SizedBox(height: 8),
              ],
              Text(
                message.messageText,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Timeago(
                    date: message.sentAt,
                    builder: (context, value) => Text(
                      value,
                      style: TextStyle(
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    _buildReadStatus(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadStatus() {
    if (message.readBy.isEmpty) {
      return const Icon(Icons.done, size: 14, color: Colors.white70);
    } else {
      return const Icon(Icons.done_all, size: 14, color: Colors.lightBlue);
    }
  }

  Widget _buildAttachedProduct(BuildContext context) {
    final imageUrl = attachedProduct?.firstImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isCurrentUser ? 0.22 : 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 54,
                    height: 54,
                    color: Colors.white30,
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
                    color: isCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attachedProduct?.formattedPrice ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.white : Theme.of(context).primaryColor,
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
