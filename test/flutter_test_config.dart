import 'dart:async';

import 'package:buy_control/app/i18n/app_translations.dart';
import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Roda antes de cada arquivo de teste: carrega os textos de `assets/i18n`
/// e deixa o português ativo, como no app. Assim os testes enxergam os
/// textos reais (e não as chaves).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await AppLocale.loadTranslations();
  Get.addTranslations(AppTranslations().keys);
  Get.locale = AppLocale.ptBR;
  await testMain();
}
