String formatChatTimestamp(DateTime timestamp, {DateTime? now}) {
  final local = timestamp.toLocal();
  final reference = (now ?? DateTime.now()).toLocal();

  final isSameDay =
      local.year == reference.year &&
      local.month == reference.month &&
      local.day == reference.day;

  if (isSameDay) {
    return _formatTime(local);
  }

  return _formatMonthDay(local);
}

String formatChatDateLabel(DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final reference = (now ?? DateTime.now()).toLocal();

  if (local.year == reference.year) {
    return _formatMonthDay(local);
  }

  return '${_monthName(local.month)} ${local.day}, ${local.year}';
}

String _formatTime(DateTime value) {
  final minute = value.minute.toString().padLeft(2, '0');
  final isPm = value.hour >= 12;
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final meridiem = isPm ? 'PM' : 'AM';
  return '$hour12:$minute $meridiem';
}

String _formatMonthDay(DateTime value) {
  return '${_monthName(value.month)} ${value.day}';
}

String _monthName(int month) {
  const monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return monthNames[month - 1];
}