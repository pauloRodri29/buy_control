import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primárias
  static const Color primary = Color(0xFF1C1C1C);
  static const Color secondary = Color(0xFFFFFFFF);

  // Tons de fundo
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1F1F1F);
  static const Color buttonPrimaryDark = Color(0xFF2C2C2C);
  static const Color buttonSecondaryDark = Color(0xFF333333);
  static const Color borderDark = Color(0xFF444444);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF5F5F5);
  static const Color buttonPrimaryLight = Color(0xFF1C1C1C);
  static const Color buttonSecondaryLight = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFCCCCCC);

  // Texto
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textOnDarkButton = Color(0xFFFFFFFF);

  static const Color textPrimaryLight = Color(0xFF1C1C1C);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textOnLightButton = Color(0xFFFFFFFF);

  // Ações
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);

  // Extras
  static const Color iconActiveDark = Color(0xFFFFFFFF);
  static const Color iconActiveLight = Color(0xFF1C1C1C);
  static const Color overlayDark = Color.fromRGBO(0, 0, 0, 0.2);
  static const Color overlayLight = Color.fromRGBO(0, 0, 0, 0.05);
}
