import 'package:flutter/material.dart';

/// Paleta categórica local para os gráficos do Dashboard. Não é um token do
/// design system (que não define cores por série) — mantida centralizada
/// aqui para não espalhar hexadecimais pelos widgets de gráfico.
///
/// As seis cores seguem a ordem fixa validada para separação sob daltonismo
/// (deuteranopia/protanopia) e contraste normal-vision, com as 4 primeiras
/// aprovadas para comparação par-a-par completa (uso em pizza/donut); as
/// duas últimas ficam na faixa aceitável desde que acompanhadas de rótulo
/// direto (nome + percentual na legenda), o que os gráficos abaixo sempre
/// fazem.
class DashboardChartPalette {
  DashboardChartPalette._();

  static const List<Color> _light = [
    Color(0xFF2A78D6),
    Color(0xFF008300),
    Color(0xFFE87BA4),
    Color(0xFFEDA100),
    Color(0xFF1BAF7A),
    Color(0xFFEB6834),
  ];

  static const List<Color> _dark = [
    Color(0xFF3987E5),
    Color(0xFF008300),
    Color(0xFFD55181),
    Color(0xFFC98500),
    Color(0xFF199E70),
    Color(0xFFD95926),
  ];

  static const Color other = Color(0xFF898781);

  static Color slot(int index, bool isDark) {
    final colors = isDark ? _dark : _light;
    return colors[index % colors.length];
  }
}
