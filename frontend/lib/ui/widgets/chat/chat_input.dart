import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  const ChatInputArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Keep column as tight as possible
        children: [
          Row(
            children: [
              // Message Text Field
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F0F0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child:
                            Icon(Icons.image_outlined, color: Colors.blue[400]),
                      ),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Type here ...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send Button
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF1F0F0),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.grey),
                  onPressed: () {
                    // Send message logical action
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling Chips for quick replies
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickReplyChip("Is this available?"),
                const SizedBox(width: 10),
                _buildQuickReplyChip("What's the price?"),
                const SizedBox(width: 10),
                _buildQuickReplyChip("Hi, there"),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Quick Reply Button Chip
  Widget _buildQuickReplyChip(String label) {
    return InkWell(
      onTap: () {
        // Chip action
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF00A2E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
