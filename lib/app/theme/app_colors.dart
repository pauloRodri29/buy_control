import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1C1C1C);
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF4CAF50);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceVariantDark = Color(0xFF262628);
  static const Color cardDark = Color(0xFF1F1F1F);
  static const Color buttonPrimaryDark = Color(0xFF2C2C2C);
  static const Color buttonSecondaryDark = Color(0xFF333333);
  static const Color borderDark = Color(0xFF3A3A3C);

  static const Color backgroundLight = Color(0xFFF7F7F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEFEFF2);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color buttonPrimaryLight = Color(0xFF1C1C1C);
  static const Color buttonSecondaryLight = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFDDDDE1);

  static const Color textPrimaryDark = Color(0xFFEDEDED);
  static const Color textSecondaryDark = Color(0xFFA5A5A8);
  static const Color textOnDarkButton = Color(0xFFFFFFFF);

  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF6B6B70);
  static const Color textOnLightButton = Color(0xFFFFFFFF);

  static const Color error = Color(0xFFE5484D);
  static const Color errorSurfaceDark = Color(0xFF3A1F20);
  static const Color errorSurfaceLight = Color(0xFFFCE9E9);
  static const Color warning = Color(0xFFF5A623);
  static const Color success = Color(0xFF30A46C);

  static const Color iconActiveDark = Color(0xFFFFFFFF);
  static const Color iconActiveLight = Color(0xFF1C1C1C);
  static const Color overlayDark = Color.fromRGBO(0, 0, 0, 0.45);
  static const Color overlayLight = Color.fromRGBO(0, 0, 0, 0.25);

  static Color surface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color surfaceVariant(bool isDark) => isDark ? surfaceVariantDark : surfaceVariantLight;
  static Color textPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
  static Color border(bool isDark) => isDark ? borderDark : borderLight;
  static Color background(bool isDark) => isDark ? backgroundDark : backgroundLight;
}
