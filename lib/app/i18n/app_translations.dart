import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:get/get.dart';

/// Traduções do GetX: um mapa por idioma, lido de `assets/i18n/` por
/// [AppLocale.loadTranslations]. Chave semântica → texto.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => AppLocale.translationMaps;
}
