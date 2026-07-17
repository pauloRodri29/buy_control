import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:flutter/material.dart';

/// Estilos de texto semânticos construídos sobre a escala de [AppFontSizes].
class AppTypography {
  AppTypography._();

  static TextStyle titleLarge(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz12,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle titleMedium(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz11,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle titleSmall(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz09,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle bodyLarge(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz09,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle bodyMedium(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz08,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle bodySmall(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz06,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary(isDark),
      );

  static TextStyle labelLarge(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz07,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle labelMedium(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz06,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary(isDark),
      );

  static TextStyle labelSmall(bool isDark) => TextStyle(
        fontSize: AppFontSizes.fz04,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary(isDark),
      );
}
