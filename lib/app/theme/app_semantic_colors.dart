import 'package:flutter/material.dart';

/// Cores com significado que o [ColorScheme] do Material não cobre
/// (sucesso, aviso e a paleta categórica dos gráficos). Registradas como
/// [ThemeExtension], então seguem o tema claro/escuro e são lidas com
/// `context.semantic`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  /// Séries dos gráficos, em ordem fixa validada para separação sob
  /// daltonismo (deuteranopia/protanopia): as 4 primeiras servem para
  /// comparação par a par (pizza/donut); as duas últimas pedem rótulo
  /// direto (nome + percentual), o que os gráficos sempre mostram.
  final List<Color> chartSeries;

  /// Cor do agrupamento "Outros" nos gráficos.
  final Color chartOther;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.chartSeries,
    required this.chartOther,
  });

  /// Cor da série [index] (a paleta se repete se houver mais séries).
  Color chart(int index) => chartSeries[index % chartSeries.length];

  static const light = AppSemanticColors(
    success: Color(0xFF30A46C),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE3F4EA),
    warning: Color(0xFFF5A623),
    onWarning: Color(0xFF1C1C1E),
    warningContainer: Color(0xFFFFF3DD),
    chartSeries: [
      Color(0xFF2A78D6),
      Color(0xFF008300),
      Color(0xFFE87BA4),
      Color(0xFFEDA100),
      Color(0xFF1BAF7A),
      Color(0xFFEB6834),
    ],
    chartOther: Color(0xFF898781),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF3DB97B),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFF173626),
    warning: Color(0xFFF5A623),
    onWarning: Color(0xFF1C1C1E),
    warningContainer: Color(0xFF3D2E12),
    chartSeries: [
      Color(0xFF3987E5),
      Color(0xFF008300),
      Color(0xFFD55181),
      Color(0xFFC98500),
      Color(0xFF199E70),
      Color(0xFFD95926),
    ],
    chartOther: Color(0xFF898781),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    List<Color>? chartSeries,
    Color? chartOther,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      chartSeries: chartSeries ?? this.chartSeries,
      chartOther: chartOther ?? this.chartOther,
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
      chartSeries: [
        for (var i = 0; i < chartSeries.length; i++)
          Color.lerp(chartSeries[i], other.chartSeries[i % other.chartSeries.length], t)!,
      ],
      chartOther: Color.lerp(chartOther, other.chartOther, t)!,
    );
  }
}
