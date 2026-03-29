import 'package:flutter/material.dart';

import '../../../widgets/app_report_sheet.dart';

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

Future<ReportSheetInput?> showUserReportSheet(
  BuildContext context, {
  required String title,
}) async {
  return showReportSheet(
    context,
    title: title,
    description: 'Tell us what is wrong with this account.',
    reasons: const [
      'Spam or scam',
      'Harassment or bullying',
      'Inappropriate content',
      'Impersonation',
      'Selling prohibited items',
      'Other',
    ],
  );
}
