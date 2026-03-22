import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/colors.dart';
import '../../../../ui/widgets/full_screen_image_viewer.dart';

class ChatInput extends StatefulWidget {
  final Future<void> Function(String, List<String>) onSendMessage;
  final bool isLoading;
  final bool isSendingMessage;
  final bool isDisabled;
  final String? disabledHintText;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
    this.isSendingMessage = false,
    this.isDisabled = false,
    this.disabledHintText,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  static const int _maxImages = 4;

  late final TextEditingController _controller;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = <XFile>[];
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

  bool get _canSend =>
      !widget.isDisabled &&
      !widget.isSendingMessage &&
      (!_isEmpty || _selectedImages.isNotEmpty);

  Future<void> _pickImages() async {
    if (widget.isDisabled || widget.isSendingMessage || widget.isLoading) {
      return;
    }

    final remaining = _maxImages - _selectedImages.length;
    if (remaining <= 0) {
      return;
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1800,
    );

    if (!mounted || picked.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages.addAll(picked.take(remaining));
    });
  }

  Future<void> _handleSend() async {
    if (!_canSend) {
      return;
    }

    final message = _controller.text.trim();
    final imagePaths = _selectedImages.map((image) => image.path).toList(growable: false);

    await widget.onSendMessage(message, imagePaths);

    if (!mounted) {
      return;
    }

    _controller.clear();
    setState(() {
      _isEmpty = true;
      _selectedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedImages.isNotEmpty) ...[
                _buildSelectedImages(),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: widget.isDisabled ||
                            widget.isLoading ||
                            widget.isSendingMessage ||
                            _selectedImages.length >= _maxImages
                        ? null
                        : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    color: _selectedImages.length >= _maxImages
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    iconSize: 26,
                    padding: const EdgeInsets.only(bottom: 4),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDE3EA)),
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: !widget.isDisabled &&
                            !widget.isLoading &&
                            !widget.isSendingMessage,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.disabledHintText ?? 'Message...',
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                          fillColor: Colors.transparent,
                          filled: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _buildSendButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _canSend ? _handleSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _canSend
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _canSend ? null : AppColors.border,
        ),
        child: Center(
          child: widget.isSendingMessage
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Widget _buildSelectedImages() {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          return Stack(
            children: [
              GestureDetector(
                onTap: () => FullScreenImageViewer.show(
                  context,
                  image.path,
                  allImages: _selectedImages.map((item) => item.path).toList(growable: false),
                  initialIndex: index,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(image.path),
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 82,
                      height: 82,
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
