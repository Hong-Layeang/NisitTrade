class AppValues {
  AppValues._();

  // Opacity values
  static const double opacitySurface = 0.05;
  static const double opacityOverlay = 0.6;
  static const double opacityDisabled = 0.3;
  static const double opacityHover = 0.1;
  static const double opacityPressed = 0.45;
  static const double opacityDivider = 0.12;
  static const double opacityBackdrop = 0.95;

  // Pagination defaults
  static const int defaultOffset = 0;
  
  // Image constraints
  static const int maxImageQuality = 85;
  static const int imageCompressionQuality = 70;
  
  // Thresholds
  static const int dragDismissThreshold = 110;
  static const int velocityDismissThreshold = 700;
  static const double progressClampMax = 1.0;
  static const double progressClampMin = 0.0;
  
  // Gesture/Animation thresholds
  static const double dragProgressDivisor = 320.0;
  static const double maxBlurSigma = 18.0;
  
  // Border widths
  static const double borderThin = 0.5;
  static const double borderStandard = 1.0;
  static const double borderThick = 2.0;
  
  // Stroke widths
  static const double strokeThin = 1.5;
  static const double strokeStandard = 2.0;
  static const double strokeThick = 3.0;
}
