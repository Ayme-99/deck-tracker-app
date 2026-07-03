import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles/colors.dart';
import 'package:deck_tracker_app/styles/text_styles.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = isDark ? ThemeData.dark() : ThemeData.light();

  final background = isDark ? AppColors.backgroundDark : AppColors.background;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
  final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

  return base.copyWith(
    brightness: brightness,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: background,
    colorScheme: base.colorScheme.copyWith(
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: surface,
      error: AppColors.error,
      onPrimary: isDark ? textPrimary : AppColors.surface,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: AppColors.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? surface : AppColors.primary,
      foregroundColor: isDark ? textPrimary : AppColors.surface,
      elevation: 0,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: AppTextStyles.title.copyWith(color: textPrimary),
      bodyLarge: AppTextStyles.body.copyWith(color: textPrimary),
      bodyMedium: AppTextStyles.caption.copyWith(color: textPrimary),
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