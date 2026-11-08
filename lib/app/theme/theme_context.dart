import 'package:buy_control/app/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Atalhos para o tema nativo. Use sempre estes acessos em vez de cores
/// fixas ou de checar `brightness` manualmente:
///
/// ```dart
/// color: context.colors.onSurfaceVariant
/// style: context.text.titleMedium
/// color: context.semantic.success
/// ```
extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppSemanticColors get semantic => Theme.of(this).extension<AppSemanticColors>()!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
