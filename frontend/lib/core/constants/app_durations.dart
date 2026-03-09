class AppDurations {
  AppDurations._();

  // Standard durations
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration splash = Duration(milliseconds: 1200);
  static const Duration splashDelay = Duration(milliseconds: 1800);

  // Debounce durations
  static const Duration debounceShort = Duration(milliseconds: 300);
  static const Duration debounceMedium = Duration(milliseconds: 500);
  static const Duration debounceLong = Duration(milliseconds: 800);
}
