import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get display => const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 40 / 34,
        letterSpacing: -0.04,
        color: AppColors.text,
      );

  static TextStyle get headlineLg => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 32 / 24,
        letterSpacing: -0.02,
        color: AppColors.text,
      );

  static TextStyle get headlineMd => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.text,
      );

  static TextStyle get bodyLg => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 24 / 16,
        color: AppColors.text,
      );

  static TextStyle get bodyMd => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 20 / 14,
        color: AppColors.text,
      );

  static TextStyle get labelLg => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.05,
        color: AppColors.text,
      );

  static TextStyle get labelSm => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 14 / 10,
        letterSpacing: 0.02,
        color: AppColors.text,
      );
}
