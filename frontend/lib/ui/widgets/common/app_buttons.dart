import 'package:flutter/material.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final Widget? leading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        if (isLoading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ],
        Flexible(child: Text(label)),
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: child,
        ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
