import 'package:flutter/material.dart';

/// Dialog for editing a comment
class EditCommentDialog extends StatefulWidget {
  final String initialContent;

  const EditCommentDialog({
    super.key,
    required this.initialContent,
  });

  /// Shows the edit comment dialog
  static Future<String?> show(
    BuildContext context, {
    required String initialContent,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => EditCommentDialog(
        initialContent: initialContent,
      ),
    );
  }

  @override
  State<EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<EditCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Comment'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        minLines: 3,
        decoration: const InputDecoration(
          hintText: 'Write your comment...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final content = _controller.text.trim();
            if (content.isNotEmpty) {
              Navigator.of(context).pop(content);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
