import 'package:flutter/material.dart';

/// Configuração única dos ícones do app.
///
/// Os ícones vêm da fonte variável **Material Symbols** (`Symbols.*`, do
/// pacote `material_symbols_icons`), que respeita peso, preenchimento,
/// grade e tamanho óptico — a fonte antiga `Icons.*` ignora esses eixos.
///
/// Os valores abaixo entram no `iconTheme` do [ThemeData] (e nos temas de
/// componentes que definem ícones próprios), então valem para todo
/// `Icon(...)` do app sem precisar de um widget próprio. Para mudar o
/// traço de todos os ícones, altere [weight] aqui.
///
/// Ícone "marcado" (ex.: item selecionado) usa preenchimento pontual:
/// `Icon(Symbols.check_circle, fill: 1)`.
abstract final class AppIconStyle {
  /// Espessura do traço (100 a 700). 200 = traço fino.
  static const double weight = 200;

  /// 0 = contorno; 1 = preenchido.
  static const double fill = 0;

  /// Ajuste fino de espessura (-25 a 200); 0 = padrão.
  static const double grade = 0;

  /// Tamanho óptico (20 a 48), afinado para o tamanho padrão de 24.
  static const double opticalSize = 24;

  /// [IconThemeData] com os eixos acima; [color] e [size] são opcionais
  /// para os temas de componente que só mudam a cor.
  static IconThemeData theme({Color? color, double? size}) {
    return IconThemeData(
      color: color,
      size: size,
      weight: weight,
      fill: fill,
      grade: grade,
      opticalSize: opticalSize,
    );
  }
}
