import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;

  const ChatBubble({
    Key? key,
    required this.text,
    required this.time,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00A2E8) : const Color(0xFFF1F0F0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            // The pointed corner alternates based on who is sending the message
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductChatBubble extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final String productDescription;
  final String price;
  final String text;
  final String time;

  const ProductChatBubble({
    Key? key,
    required this.imageUrl,
    required this.productName,
    required this.productDescription,
    required this.price,
    required this.text,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFF00A2E8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Embedded Product Details Area
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.white24,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productDescription,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Price Tag Badge
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF00A2E8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            // Accompanying Message text
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
