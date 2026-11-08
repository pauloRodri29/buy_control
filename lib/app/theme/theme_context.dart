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
///
/// (Para o [ThemeData] inteiro, use `Theme.of(context)`: `context.theme`
/// já existe como extensão do GetX.)
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppSemanticColors get semantic => Theme.of(this).extension<AppSemanticColors>()!;
}
