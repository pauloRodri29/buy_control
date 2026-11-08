import 'package:flutter/material.dart';

/// Cores com significado que o [ColorScheme] do Material não cobre
/// (sucesso e aviso). Registradas como [ThemeExtension], então seguem o
/// tema claro/escuro e são lidas com `context.semantic`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF30A46C),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE3F4EA),
    warning: Color(0xFFF5A623),
    onWarning: Color(0xFF1C1C1E),
    warningContainer: Color(0xFFFFF3DD),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF3DB97B),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFF173626),
    warning: Color(0xFFF5A623),
    onWarning: Color(0xFF1C1C1E),
    warningContainer: Color(0xFF3D2E12),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
    );
  }
}
