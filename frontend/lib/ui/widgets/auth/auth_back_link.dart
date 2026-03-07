import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class AuthBackLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AuthBackLink({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
