import 'package:buy_control/app/bindings/initial_binding.dart';
import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/brand/font_licenses.dart';
import 'package:buy_control/app/bootstrap/app_bootstrap.dart';
import 'package:buy_control/app/errors/app_error_handler.dart';
import 'package:buy_control/app/routes/pages.dart';
import 'package:buy_control/app/theme/app_theme.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandler.install();
  registerFontLicenses();
  await initializeDateFormatting('pt_BR');
  await AppBootstrap.run();
  // Registrado antes do runApp: o app precisa do modo de tema já no
  // primeiro frame (e o Hive já está aberto pelo bootstrap).
  Get.put(ThemeController(AppMetaStore()), permanent: true);
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
        // Textos nativos do Material (diálogos, seletores de data/hora,
        // tooltips como "Voltar", menus etc.) em português.
        locale: const Locale('pt', 'BR'),
        fallbackLocale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
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
