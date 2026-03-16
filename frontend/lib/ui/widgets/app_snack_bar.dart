import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/errors/app_error_messages.dart';

/// Centralized app feedback helper for transient snack messages.
class AppSnackBar {
  AppSnackBar._();

  static const Duration _defaultDuration = Duration(seconds: 2);
  static const Color _defaultBackground = Color(0xFF121417);
  static const Color _errorBackground = Color(0xFFB3261E);
  static const TextStyle _messageStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static void show(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
    Color? backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: behavior,
          backgroundColor: backgroundColor ?? _defaultBackground,
          content: Text(
            message,
            style: _messageStyle,
          ),
          duration: duration,
        ),
      );
  }

  static void showUndo(
    BuildContext context,
    String message, {
    required Future<void> Function() onUndo,
    String actionLabel = 'UNDO',
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
    Color? backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: behavior,
          backgroundColor: backgroundColor ?? _defaultBackground,
          content: Text(
            message,
            style: _messageStyle,
          ),
          action: SnackBarAction(
            label: actionLabel,
            textColor: Colors.white,
            onPressed: () {
              unawaited(onUndo());
            },
          ),
          duration: duration,
        ),
      );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      AppErrorMessages.resolve(message),
      backgroundColor: _errorBackground,
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message);
  }

  static void info(BuildContext context, String message) {
    show(context, message);
  }
}