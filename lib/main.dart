import 'package:buy_control/app/bindings/initial_binding.dart';
import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/brand/font_licenses.dart';
import 'package:buy_control/app/bootstrap/app_bootstrap.dart';
import 'package:buy_control/app/errors/app_error_handler.dart';
import 'package:buy_control/app/i18n/app_translations.dart';
import 'package:buy_control/app/i18n/locale_controller.dart';
import 'package:buy_control/app/routes/pages.dart';
import 'package:buy_control/app/theme/app_theme.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandler.install();
  registerFontLicenses();
  for (final language in AppLocale.languages) {
    await initializeDateFormatting(language.code);
  }
  // Traduções (assets/i18n) e idioma do aparelho já valem no bootstrap: os
  // catálogos padrão são criados no idioma em uso na primeira execução.
  await AppLocale.loadTranslations();
  Get.addTranslations(AppTranslations().keys);
  Get.locale = AppLocale.fromDevice(Get.deviceLocale);
  await AppBootstrap.run();
  // Registrados antes do runApp: o app precisa do tema e do idioma já no
  // primeiro frame (e o Hive já está aberto pelo bootstrap).
  final metaStore = AppMetaStore();
  Get.put(ThemeController(metaStore), permanent: true);
  final localeController = Get.put(LocaleController(metaStore), permanent: true);
  Get.locale = localeController.locale;
  runApp(const GastoLogApp());
}

class GastoLogApp extends StatelessWidget {
  const GastoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: AppBrand.name,
        // Idioma escolhido em Configurações (ou o do aparelho). Vale para
        // os textos do app (`.tr`) e os nativos do Material (diálogos,
        // seletores de data, tooltips como "Voltar"). Chave que faltar num
        // idioma aparece em português (fallback).
        translations: AppTranslations(),
        locale: Get.find<LocaleController>().locale,
        fallbackLocale: AppLocale.source,
        supportedLocales: AppLocale.supported,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialBinding: InitialBinding(),
        initialRoute: Routes.SPLASH,
        getPages: Pages.pages,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.mode,
      ),
    );
  }
}
