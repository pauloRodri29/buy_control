import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Um idioma oferecido pelo app.
class AppLanguage {
  final Locale locale;

  /// Nome escrito no próprio idioma (não traduz), como aparece no seletor.
  final String nativeName;

  /// JSON com os textos deste idioma (chave semântica → texto).
  final String asset;

  const AppLanguage({required this.locale, required this.nativeName, required this.asset});

  /// Código usado no GetX, no `intl` e no armazenamento: "pt_BR", "en_US".
  String get code => locale.toString();
}

/// Idiomas do app. Cada um tem seu JSON em `assets/i18n/` com as mesmas
/// chaves semânticas (`common.save`), usadas no código com `.tr`
/// (`'common.save'.tr`) ou `.trParams`.
///
/// Para adicionar um idioma: crie `assets/i18n/<código>.json` (mesmas chaves
/// de `pt_BR.json`) e registre-o em [languages]. Seletor em Configurações,
/// `GetMaterialApp`, formatação de datas e catálogos padrão passam a
/// incluí-lo sozinhos; o teste `test/core/i18n/translations_test.dart` cobra
/// as chaves faltando.
abstract final class AppLocale {
  static const ptBR = Locale('pt', 'BR');
  static const enUS = Locale('en', 'US');

  static const languages = [
    AppLanguage(locale: ptBR, nativeName: 'Português (Brasil)', asset: 'assets/i18n/pt_BR.json'),
    AppLanguage(locale: enUS, nativeName: 'English', asset: 'assets/i18n/en_US.json'),
  ];

  /// Idioma de referência: completo, e reserva quando falta uma chave em
  /// outro idioma.
  static const source = ptBR;

  /// Idioma inicial quando o aparelho está num idioma que o app não tem.
  static const deviceFallback = enUS;

  static final _translations = <String, Map<String, String>>{};

  /// Lê os JSON de tradução de `assets/i18n`. Chamado uma vez no `main`,
  /// antes do bootstrap e do `runApp`.
  static Future<void> loadTranslations([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    for (final language in languages) {
      final decoded = jsonDecode(await assets.loadString(language.asset)) as Map<String, dynamic>;
      _translations[language.code] = decoded.cast<String, String>();
    }
  }

  /// Textos carregados, por código: {"pt_BR": {...}, "en_US": {...}}.
  /// Vazio antes de [loadTranslations].
  static Map<String, Map<String, String>> get translationMaps => Map.unmodifiable(_translations);

  static List<Locale> get supported => [for (final l in languages) l.locale];

  /// Idioma em uso (o do GetX), com o idioma de referência como padrão.
  static AppLanguage get current => _byLanguageCode(Get.locale) ?? languageOf(source);

  /// Código para o `intl` (`DateFormat`, `table_calendar`): "pt_BR", "en_US".
  static String get intl => current.code;

  static AppLanguage languageOf(Locale locale) => _byLanguageCode(locale) ?? languages.first;

  /// Idioma inicial quando o usuário ainda não escolheu: o do aparelho, se
  /// o app o tiver (pela língua, ex.: pt_PT → pt_BR); senão [deviceFallback].
  static Locale fromDevice(Locale? device) => _byLanguageCode(device)?.locale ?? deviceFallback;

  /// Converte o código salvo ("pt_BR"/"en_US") de volta em [Locale].
  static Locale? parse(String? code) {
    for (final l in languages) {
      if (l.code == code) return l.locale;
    }
    return null;
  }

  static String nativeName(Locale locale) => languageOf(locale).nativeName;

  static AppLanguage? _byLanguageCode(Locale? locale) {
    for (final l in languages) {
      if (l.locale.languageCode == locale?.languageCode) return l;
    }
    return null;
  }
}
