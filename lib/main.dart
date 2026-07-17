import 'package:buy_control/app/bindings/initial_binding.dart';
import 'package:buy_control/app/bootstrap/app_bootstrap.dart';
import 'package:buy_control/app/routes/pages.dart';
import 'package:buy_control/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await AppBootstrap.run();
  runApp(const BuyControlApp());
}

class BuyControlApp extends StatelessWidget {
  const BuyControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuyControl',
      initialBinding: InitialBinding(),
      initialRoute: Routes.INITIAL,
      getPages: Pages.pages,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
