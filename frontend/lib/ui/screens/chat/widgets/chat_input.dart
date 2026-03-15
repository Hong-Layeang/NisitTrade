import 'package:flutter/material.dart';
import '../../../../data/models/product.dart';

class ChatInput extends StatefulWidget {
  final Future<void> Function(String, bool) onSendMessage;
  final bool isLoading;
  final bool isSendingMessage;
  final Product? attachedProduct;
  final bool attachProductOnCompose;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
    this.isSendingMessage = false,
    this.attachedProduct,
    this.attachProductOnCompose = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _controller;
  bool _isEmpty = true;
  late bool _includeAttachedProduct;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_handleTextChange);
    _includeAttachedProduct =
        widget.attachedProduct != null && widget.attachProductOnCompose;
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attachProductOnCompose != oldWidget.attachProductOnCompose) {
      _includeAttachedProduct =
          widget.attachedProduct != null && widget.attachProductOnCompose;
    }
    if (widget.attachedProduct == null && oldWidget.attachedProduct != null) {
      _includeAttachedProduct = false;
    }
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

  Future<void> _handleSend() async {
    final message = _controller.text.trim();
    if (message.isNotEmpty && !widget.isSendingMessage) {
      final shouldAttach = _includeAttachedProduct;
      await widget.onSendMessage(message, shouldAttach);
      _controller.clear();
      setState(() {
        _isEmpty = true;
        if (shouldAttach) {
          _includeAttachedProduct = false;
        }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_includeAttachedProduct && widget.attachedProduct != null) ...[
              _buildProductAttachment(widget.attachedProduct!),
              const SizedBox(height: 8),
            ],
            Row(
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
            if (!_includeAttachedProduct && widget.attachedProduct != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.isSendingMessage
                      ? null
                      : () {
                          setState(() {
                            _includeAttachedProduct = true;
                          });
                        },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Attach product'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAttachment(Product product) {
    final imageUrl = product.firstImageUrl;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined, size: 18),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  product.formattedPrice,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _includeAttachedProduct = false;
              });
            },
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Remove attached product',
          ),
        ],
      ),
    );
  }
}
