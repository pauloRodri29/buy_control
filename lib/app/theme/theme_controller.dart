import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
        ThemeMode.system => 'common.automaticSystem'.tr,
        ThemeMode.light => 'common.light'.tr,
        ThemeMode.dark => 'common.dark'.tr,
      };
}

/// Preferência de tema claro/escuro/sistema. Persistida no [AppMetaStore]
/// e aplicada no `themeMode` nativo do app (ver `main.dart`).
class ThemeController extends GetxController {
  final AppMetaStore metaStore;

  ThemeController(this.metaStore);

  ThemeMode get mode {
    final saved = metaStore.themeMode;
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  Future<void> setMode(ThemeMode mode) async {
    await metaStore.setThemeMode(mode.name);
    update();
  }
}
