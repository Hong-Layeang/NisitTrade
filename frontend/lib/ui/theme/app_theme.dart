import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.accent,
              width: 2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
