import 'dart:io';

import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/theme/app_semantic_colors.dart';
import 'package:buy_control/app/theme/app_theme.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('AppTheme', () {
    for (final brightness in Brightness.values) {
      test('tema ${brightness.name} usa o ColorScheme e as cores semânticas do app', () {
        final theme = AppTheme.build(brightness);
        expect(theme.brightness, brightness);
        // Verde-petróleo da marca (versão clara no tema escuro).
        expect(theme.colorScheme.primary, brightness == Brightness.dark ? AppBrand.tealLight : AppBrand.teal);
        expect(theme.textTheme.bodyMedium?.fontFamily, AppBrand.fontFamily);
        expect(theme.extension<AppSemanticColors>(), isNotNull);
        // Nenhum componente cai na paleta padrão (lilás) do Material 3.
        expect(theme.colorScheme, brightness == Brightness.dark ? AppTheme.darkScheme : AppTheme.lightScheme);
      });
    }

    testWidgets('context.colors/semantic seguem o tema ativo', (tester) async {
      late ColorScheme colors;
      late AppSemanticColors semantic;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Builder(builder: (context) {
          colors = context.colors;
          semantic = context.semantic;
          return const SizedBox();
        }),
      ));
      expect(colors.brightness, Brightness.dark);
      expect(semantic, AppSemanticColors.dark);
    });
  });

  group('ThemeController', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buy_control_theme_test');
      Hive.init(tempDir.path);
      await Hive.openBox(HiveBoxRegistry.appMeta);
    });

    tearDown(() async {
      Get.reset();
      await Hive.deleteFromDisk();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('padrão é seguir o sistema e a escolha é persistida', () async {
      final controller = ThemeController(AppMetaStore());
      expect(controller.mode, ThemeMode.system);

      await controller.setMode(ThemeMode.dark);
      // Nova instância (como ao reabrir o app) lê o valor salvo.
      expect(ThemeController(AppMetaStore()).mode, ThemeMode.dark);
    });
  });
}
