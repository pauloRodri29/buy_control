import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Identidade do app: nome, textos de apoio, fontes e as cores fixas da
/// marca.
///
/// Telas não escrevem o nome do app nem a frase de apoio diretamente:
/// leem daqui. As cores abaixo são as da marca (logo, ícone e splash) e
/// não mudam com o tema; o [ColorScheme] em `app_theme.dart` parte delas.
abstract final class AppBrand {
  static const name = 'GastoLog';
  // Textos traduzíveis (getters, para acompanhar a troca de idioma).
  static String get tagline => 'common.everyExpenseRecorded'.tr;
  static String get description => 'common.spendingPlanningForecasting'.tr;

  /// Fonte do app (embutida em `assets/fonts`, funciona offline).
  static const fontFamily = 'PlusJakartaSans';

  /// Fonte monoespaçada da splash e do logo, no estilo terminal.
  static const monoFontFamily = 'JetBrainsMono';

  /// Verde-petróleo: cor principal.
  static const teal = Color(0xFF0F766E);

  /// Verde-petróleo claro, usado como principal no tema escuro.
  static const tealLight = Color(0xFF14B8A6);

  /// Âmbar: cor de destaque (cursor do logo, moeda do ícone).
  static const amber = Color(0xFFF59E0B);

  /// Fundo da splash e do ícone: um verde-petróleo quase preto, como a
  /// tela de um terminal.
  static const terminal = Color(0xFF0B1F1E);

  /// Texto secundário sobre [terminal].
  static const terminalMuted = Color(0xFF7FA8A3);
}
