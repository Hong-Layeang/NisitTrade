import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class AppActionChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color labelColor;
  final VoidCallback? onTap;
  final bool isDisabled;
  final Color backgroundColor;
  final Color borderColor;

  const AppActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.onTap,
    this.isDisabled = false,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
