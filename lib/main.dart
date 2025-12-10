import 'package:buy_control/app/routes/pages.dart';
import 'package:buy_control/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('box_buy_control');
  runApp(const BuyControlApp());
}

class BuyControlApp extends StatelessWidget {
  const BuyControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuyControl',
      // Rotas
      initialRoute: Routes.INITIAL,
      getPages: Pages.pages,
      // Tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Definir tema baseado no sistema
      themeMode: ThemeMode.system, // muda automaticamente entre light/dark
    );
  }
}
