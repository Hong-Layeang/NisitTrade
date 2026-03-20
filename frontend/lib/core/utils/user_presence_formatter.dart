import 'package:flutter/material.dart';

import '../constants/colors.dart';

String buildPresenceLabel({
  required bool isOnline,
  DateTime? lastSeenAt,
  DateTime? now,
}) {
  if (isOnline) {
    return 'Online';
  }

  if (lastSeenAt == null) {
    return 'Offline';
  }

  final reference = now ?? DateTime.now();
  final difference = reference.difference(lastSeenAt);

  if (difference.inSeconds < 60) {
    return 'Offline just now';
  }
  if (difference.inMinutes < 60) {
    return 'Offline ${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return 'Offline ${difference.inHours}h ago';
  }
  if (difference.inDays < 7) {
    return 'Offline ${difference.inDays}d ago';
  }

  return 'Offline ${lastSeenAt.day}/${lastSeenAt.month}/${lastSeenAt.year}';
}

Color presenceColor({required bool isOnline}) {
  if (isOnline) {
    return const Color(0xFF34C759);
  }
  return AppColors.textSecondary;
}
