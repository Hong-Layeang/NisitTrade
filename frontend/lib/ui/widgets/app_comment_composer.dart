import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class AppCommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final bool isSubmitting;
  final String hintText;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final bool pinnedToBottom;

  const AppCommentComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.focusNode,
    this.isSubmitting = false,
    this.hintText = 'Write a comment...',
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 4,
    this.pinnedToBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final composerRow = Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: minLines,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: const InputDecoration(
              hintText: 'Write a comment...',
              counterText: '',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
            ).copyWith(hintText: hintText),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isSubmitting ? null : onSend,
          icon: isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, color: AppColors.primary),
        ),
      ],
    );

    if (!pinnedToBottom) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: composerRow,
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: composerRow,
      ),
    );
  }
}
