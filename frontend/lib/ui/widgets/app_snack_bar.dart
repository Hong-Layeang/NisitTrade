import 'package:flutter/material.dart';

/// Centralized app feedback helper for transient snack messages.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: behavior,
        ),
      );
  }

  static void error(BuildContext context, String message) {
    show(context, message);
  }

  static void success(BuildContext context, String message) {
    show(context, message);
  }
}