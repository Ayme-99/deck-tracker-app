import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles/colors.dart';
import 'package:deck_tracker_app/styles/sizes.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading = TextStyle(
    fontSize: AppSizes.textXL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: AppSizes.textL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: AppSizes.textM,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: AppSizes.textS,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: AppSizes.textM,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
}
