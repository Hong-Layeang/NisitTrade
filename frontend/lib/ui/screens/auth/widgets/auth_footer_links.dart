import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AuthFooterLinks extends StatelessWidget {
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;
  final String termsLabel;
  final String privacyLabel;

  const AuthFooterLinks({
    super.key,
    this.onTermsTap,
    this.onPrivacyTap,
    this.termsLabel = 'Terms of use',
    this.privacyLabel = 'privacy policy',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTermsTap,
          child: Text(
            termsLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '|',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        GestureDetector(
          onTap: onPrivacyTap,
          child: Text(
            privacyLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
