import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;
  final bool isSendingMessage;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    this.isLoading = false,
    this.isSendingMessage = false,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _controller;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    setState(() {
      _isEmpty = _controller.text.trim().isEmpty;
    });
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isNotEmpty && !widget.isSendingMessage) {
      widget.onSendMessage(message);
      _controller.clear();
      setState(() {
        _isEmpty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !widget.isLoading && !widget.isSendingMessage,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isEmpty || widget.isSendingMessage ? null : _handleSend,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isEmpty || widget.isSendingMessage
                      ? Colors.grey[300]
                      : Theme.of(context).primaryColor,
                ),
                padding: const EdgeInsets.all(12),
                child: widget.isSendingMessage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
