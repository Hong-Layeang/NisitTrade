import 'package:flutter/material.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import '../../../data/models/product.dart';

class ChatScreen extends StatelessWidget {
  final Product? initialProduct;

  const ChatScreen({
    Key? key,
    this.initialProduct,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildDateSeparator("Today"),
                const SizedBox(height: 20),
                if (initialProduct != null) ...[
                  ProductChatBubble(
                    imageUrl: initialProduct!.imageUrls.isNotEmpty
                        ? initialProduct!.imageUrls.first
                        : 'https://via.placeholder.com/150',
                    productName: initialProduct!.title,
                    productDescription: initialProduct!.description ?? '',
                    price: initialProduct!.formattedPrice,
                    text: "Hey, do you still have the item for sale?",
                    time: "8:51 AM",
                  ),
                  const SizedBox(height: 16),
                ],
                const ChatBubble(
                  text: "Yes, still available! What would you like to know?",
                  time: "9:00 AM",
                  isMe: false, // Grey bubble on the left
                ),
                const SizedBox(height: 16),
                const ChatBubble(
                  text: "Can you confirm the price again?",
                  time: "9:08 AM",
                  isMe: true, // Blue bubble on the right
                ),
               ],
            ),
          ),
          
          // Bottom Input & Quick Replies
          const ChatInputArea(),
        ],
      ),
    );
  }

  // App Bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      titleSpacing: 0,
      title: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Replace with actual image
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Virak Dara',
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'cadt',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        )
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.grey[200], height: 1.0), // Bottom border
      ),
    );
  }

  // Date Separator
  Widget _buildDateSeparator(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }
}
