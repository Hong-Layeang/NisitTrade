import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:frontend/data/models/conversation.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
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
}
