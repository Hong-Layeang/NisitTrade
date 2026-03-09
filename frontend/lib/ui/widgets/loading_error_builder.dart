import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_values.dart';

/// A reusable widget that handles loading, error, and success states.
/// Reduces boilerplate across screens for common state management patterns.
class LoadingErrorBuilder extends StatelessWidget {
  /// Whether data is currently loading
  final bool isLoading;
  
  /// Error message to display if present
  final String? error;
  
  /// Callback for retry action when error occurs
  final VoidCallback? onRetry;
  
  /// The widget to display when not loading and no error
  final Widget child;
  
  /// Optional custom loading indicator
  final Widget? loadingWidget;
  
  /// Optional custom error widget builder
  final Widget Function(String error, VoidCallback? onRetry)? errorBuilder;
  
  /// Whether to show error as overlay (default) or replace content
  final bool errorAsOverlay;
  
  /// Whether this is the initial load (shows centered spinner) or subsequent load
  final bool isInitialLoad;

  const LoadingErrorBuilder({
    super.key,
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.child,
    this.loadingWidget,
    this.errorBuilder,
    this.errorAsOverlay = false,
    this.isInitialLoad = true,
  });

  @override
  Widget build(BuildContext context) {
    // Show error
    if (error != null && error!.isNotEmpty) {
      if (errorAsOverlay) {
        return Stack(
          children: [
            child,
            _buildErrorOverlay(context),
          ],
        );
      }
      return errorBuilder?.call(error!, onRetry) ?? _buildDefaultError(context);
    }

    // Show loading for initial load
    if (isLoading && isInitialLoad) {
      return loadingWidget ?? _buildDefaultLoading();
    }

    // Show content (with optional loading overlay for refresh)
    if (isLoading && !isInitialLoad) {
      return Stack(
        children: [
          child,
          _buildLoadingOverlay(),
        ],
      );
    }

    return child;
  }

  Widget _buildDefaultLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: AppValues.opacitySurface),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXl,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacingL),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: AppValues.opacityDisabled),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(AppDimensions.spacingL),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppDimensions.iconL,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppDimensions.spacingM),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
