import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

Future<bool> showDeleteChatConfirmation(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<String?> showUserReportReasonDialog(
  BuildContext context, {
  required String title,
}) async {
  const reasons = [
    'Spam or scam',
    'Harassment or bullying',
    'Inappropriate content',
    'Impersonation',
    'Selling prohibited items',
    'Other',
  ];

  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a reason for reporting this user.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...reasons.map(
              (reason) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(reason, style: const TextStyle(fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => Navigator.of(context).pop(reason),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );

  return result;
}
