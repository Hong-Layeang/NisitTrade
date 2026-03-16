import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_values.dart';
import '../../core/constants/colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double? value;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = AppDimensions.iconL,
    this.strokeWidth = AppValues.strokeStandard,
    this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      value: value,
      strokeWidth: strokeWidth,
      color: color,
    );

    if (size <= 0) {
      return indicator;
    }

    return SizedBox(
      width: size,
      height: size,
      child: indicator,
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool loading;
  final bool absorbPointers;
  final Color? overlayColor;
  final Widget? indicator;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.loading,
    this.absorbPointers = true,
    this.overlayColor,
    this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    if (!loading) {
      return child;
    }

    final overlay = ColoredBox(
      color:
          overlayColor ?? AppColors.background.withValues(alpha: AppValues.opacityDisabled),
      child: Center(
        child: indicator ?? const AppLoadingIndicator(),
      ),
    );

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: absorbPointers ? AbsorbPointer(child: overlay) : overlay,
        ),
      ],
    );
  }
}

class AppPageLoading extends StatelessWidget {
  final Widget? background;

  const AppPageLoading({
    super.key,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppLoadingOverlay(
        loading: true,
        absorbPointers: true,
        overlayColor: AppColors.background.withValues(alpha: AppValues.opacityBackdrop),
        child: background ?? const SizedBox.expand(),
      ),
    );
  }
}