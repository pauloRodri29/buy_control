import 'dart:ui';

import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:get/get.dart';

/// Preferência de idioma (português ou inglês). Persistida no
/// [AppMetaStore]; sem escolha salva, segue o idioma do aparelho.
class LocaleController extends GetxController {
  final AppMetaStore metaStore;

  LocaleController(this.metaStore);

  Locale get locale => AppLocale.parse(metaStore.locale) ?? AppLocale.fromDevice(Get.deviceLocale);

  /// Troca o idioma na hora: o GetX reconstrói o app com os novos textos.
  Future<void> setLocale(Locale locale) async {
    await metaStore.setLocale(locale.toString());
    await Get.updateLocale(locale);
    update();
  }
}
