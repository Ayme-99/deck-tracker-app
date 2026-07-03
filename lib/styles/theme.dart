import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles/colors.dart';
import 'package:deck_tracker_app/styles/text_styles.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.surface,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: AppColors.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      elevation: 0,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: AppTextStyles.title,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        textStyle: AppTextStyles.button,
      ),
    ),
  );
}
