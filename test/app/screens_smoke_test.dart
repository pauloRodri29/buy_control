import 'dart:io';

import 'package:buy_control/app/bindings/initial_binding.dart';
import 'package:buy_control/app/bootstrap/seed_defaults.dart';
import 'package:buy_control/app/i18n/app_translations.dart';
import 'package:buy_control/app/i18n/locale_controller.dart';
import 'package:buy_control/app/navigation/main_shell.dart';
import 'package:buy_control/app/theme/app_theme.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/categories/presentation/bindings/categories_binding.dart';
import 'package:buy_control/features/categories/presentation/pages/categories_page.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';
import 'package:buy_control/features/product_types/presentation/bindings/product_types_binding.dart';
import 'package:buy_control/features/product_types/presentation/pages/product_types_page.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/reports/presentation/bindings/reports_binding.dart';
import 'package:buy_control/features/reports/presentation/pages/reports_page.dart';
import 'package:buy_control/features/settings/presentation/bindings/settings_binding.dart';
import 'package:buy_control/features/settings/presentation/pages/about_page.dart';
import 'package:buy_control/features/settings/presentation/pages/clear_data_page.dart';
import 'package:buy_control/features/settings/presentation/pages/settings_page.dart';
import 'package:buy_control/features/auth/presentation/pages/profile_page.dart';
import 'package:buy_control/features/subscription/presentation/pages/custom_plan_builder_page.dart';
import 'package:buy_control/features/subscription/presentation/pages/my_plan_page.dart';
import 'package:buy_control/features/subscription/presentation/pages/plans_page.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';
import 'package:buy_control/features/units/presentation/bindings/units_binding.dart';
import 'package:buy_control/features/units/presentation/pages/units_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Teste de fumaça das telas: abre cada aba e as telas do menu Mais, nos
/// temas claro e escuro, em português e em inglês, num tamanho de celular,
/// com dados de exemplo.
/// Qualquer exceção de build/layout (ex.: overflow) faz o teste falhar.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await initializeDateFormatting('en_US');
    tempDir = await Directory.systemTemp.createTemp('buy_control_screens_test');
    Hive.init(tempDir.path);
    for (final name in [
      HiveBoxRegistry.appMeta,
      HiveBoxRegistry.boxes,
      HiveBoxRegistry.products,
      HiveBoxRegistry.categories,
      HiveBoxRegistry.productTypes,
      HiveBoxRegistry.units,
      HiveBoxRegistry.transactions,
      HiveBoxRegistry.boxClosures,
      HiveBoxRegistry.authSession,
      HiveBoxRegistry.reportPresets,
      HiveBoxRegistry.planBoards,
      HiveBoxRegistry.planItems,
      HiveBoxRegistry.subscription,
    ]) {
      await Hive.openBox(name);
    }

    Get.testMode = true;
    InitialBinding().dependencies();
    Get.put(ThemeController(AppMetaStore()), permanent: true);
    Get.put(LocaleController(AppMetaStore()), permanent: true);

    await SeedDefaults(
      metaStore: AppMetaStore(),
      categoryRepository: Get.find<CategoryRepository>(),
      productTypeRepository: Get.find<ProductTypeRepository>(),
      unitRepository: Get.find<UnitRepository>(),
    ).run();
    await _seedSampleData();
  });

  tearDownAll(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  final cases = [
    for (final locale in AppLocale.supported)
      for (final mode in [ThemeMode.light, ThemeMode.dark]) (locale, mode),
  ];
  for (final (locale, mode) in cases) {
    testWidgets('telas principais abrem sem erros no tema ${mode.name} ($locale)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        translations: AppTranslations(),
        locale: locale,
        fallbackLocale: AppLocale.ptBR,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        home: const MainShell(),
      ));
      await _settle(tester);

      final tabs = <String, String>{
        'common.boxes': 'Mercado do mês com um nome bem comprido para testar quebra',
        'common.products': 'Café torrado e moído extra forte',
        'common.plan': 'Fim de ano',
        'common.more': 'common.reports'.tr,
        'common.home': 'common.home'.tr,
      };
      for (final MapEntry(key: tab, value: expected) in tabs.entries) {
        await tester.tap(find.text(tab.tr).last);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: 'aba $tab');
        expect(find.textContaining(expected), findsWidgets, reason: 'conteúdo da aba $tab');
      }

      final pages = <String, (Widget Function(), Bindings?)>{
        'common.reports': (() => const ReportsPage(), ReportsBinding()),
        'common.categories': (() => const CategoriesPage(), CategoriesBinding()),
        'common.productTypes': (() => const ProductTypesPage(), ProductTypesBinding()),
        'common.units': (() => const UnitsPage(), UnitsBinding()),
        'common.settings': (() => const SettingsPage(), SettingsBinding()),
        'settings.clearData': (() => const ClearDataPage(), SettingsBinding()),
        'settings.aboutApp': (() => const AboutPage(), null),
        'common.myPlan': (() => const MyPlanPage(), null),
        'subscription.plans': (() => const PlansPage(), null),
        'subscription.builderTitle': (() => const CustomPlanBuilderPage(), null),
        'common.profile': (() => const ProfilePage(), null),
      };
      for (final MapEntry(key: name, value: (page, binding)) in pages.entries) {
        Get.to(page, binding: binding);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: 'tela $name');
        expect(find.text(name.tr), findsWidgets, reason: 'título da tela $name');
        Get.back();
        await _settle(tester);
      }
    });
  }
}

/// Avança o suficiente para carregar dados e terminar transições, sem
/// `pumpAndSettle` (o skeleton de carregamento anima indefinidamente).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _seedSampleData() async {
  final now = DateTime.now();
  final category = (await Get.find<CategoryRepository>().getAll()).dataOrNull!.first;
  final type = (await Get.find<ProductTypeRepository>().getAll()).dataOrNull!.first;
  final unit = (await Get.find<UnitRepository>().getAll()).dataOrNull!.first;

  await Get.find<BoxRepository>().create(BoxEntity(
    id: 'box-1',
    name: 'Mercado do mês com um nome bem comprido para testar quebra',
    createdAt: now,
    updatedAt: now,
  ));
  await Get.find<ProductRepository>().create(ProductEntity(
    id: 'product-1',
    name: 'Café torrado e moído extra forte',
    brand: 'Marca',
    categoryId: category.id,
    productTypeId: type.id,
    defaultUnitId: unit.id,
    referencePrice: const Money(1899),
    createdAt: now,
    updatedAt: now,
  ));
  await Get.find<PlanBoardRepository>().create(PlanBoardEntity(
    id: 'board-1',
    title: 'Fim de ano',
    description: 'Presentes e ceia',
    goal: const Money(150000),
    targetDate: DateTime(now.year, 12, 20),
    createdAt: now,
    updatedAt: now,
  ));
  for (var i = 0; i < 3; i++) {
    await Get.find<PlanItemRepository>().create(PlanItemEntity(
      id: 'item-$i',
      boardId: 'board-1',
      title: 'Item $i',
      estimatedValue: i == 2 ? null : Money(10000 * (i + 1)),
      position: i.toDouble(),
      isPurchased: i == 0,
      purchasedAt: i == 0 ? now : null,
      createdAt: now,
      updatedAt: now,
    ));
  }
}
