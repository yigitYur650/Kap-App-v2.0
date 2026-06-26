import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kap_app_front/shared/theme/app_colors.dart';
import 'package:kap_app_front/shared/theme/app_theme.dart';
import 'package:kap_app_front/shared/theme/app_typography.dart';

void main() {
  group('AppTheme Validation', () {
    test('Light theme properties should match hex design tokens', () {
      final lightTheme = AppTheme.light;

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.useMaterial3, isTrue);

      // Verify structural color mappings
      expect(lightTheme.colorScheme.surface, AppColors.lightBackground);
      expect(lightTheme.colorScheme.primary, AppColors.lightTeal);
      expect(lightTheme.colorScheme.secondary, AppColors.lightCoral);
      expect(lightTheme.colorScheme.error, AppColors.lightError);

      // Verify sub-theme overrides
      expect(lightTheme.cardTheme.color, AppColors.lightSurface);
      expect(lightTheme.bottomSheetTheme.backgroundColor, AppColors.lightSurface);
      expect(lightTheme.bottomNavigationBarTheme.backgroundColor, AppColors.lightSurface);
      expect(lightTheme.bottomNavigationBarTheme.selectedItemColor, AppColors.lightTeal);
    });

    test('Dark theme properties should match hex design tokens', () {
      final darkTheme = AppTheme.dark;

      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.useMaterial3, isTrue);

      // Verify structural color mappings
      expect(darkTheme.colorScheme.surface, AppColors.darkBackground);
      expect(darkTheme.colorScheme.primary, AppColors.darkTeal);
      expect(darkTheme.colorScheme.secondary, AppColors.darkCoral);
      expect(darkTheme.colorScheme.error, AppColors.darkError);

      // Verify sub-theme overrides
      expect(darkTheme.cardTheme.color, AppColors.darkSurface);
      expect(darkTheme.bottomSheetTheme.backgroundColor, AppColors.darkSurface);
      expect(darkTheme.bottomNavigationBarTheme.backgroundColor, AppColors.darkSurface);
      expect(darkTheme.bottomNavigationBarTheme.selectedItemColor, AppColors.darkTeal);
    });

    test('Typography text scale styles resolve correct sizes', () {
      expect(AppTypography.display.fontSize, 48.0);
      expect(AppTypography.display.fontWeight, FontWeight.w700);

      expect(AppTypography.headline.fontSize, 32.0);
      expect(AppTypography.headline.fontWeight, FontWeight.w700);

      expect(AppTypography.title.fontSize, 20.0);
      expect(AppTypography.title.fontWeight, FontWeight.w600);

      expect(AppTypography.body.fontSize, 16.0);
      expect(AppTypography.body.fontWeight, FontWeight.w400);

      expect(AppTypography.label.fontSize, 13.0);
      expect(AppTypography.label.fontWeight, FontWeight.w500);
    });
  });
}
