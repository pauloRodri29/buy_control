import 'package:buy_control/app/bootstrap/seed_defaults.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/planning/data/datasources/local/plan_hive_data_sources.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/reports/data/repositories/report_preset_repository.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';

enum ClearDataScope { boxes, products, history, planning, reports, preferences, all }

/// Operação de manutenção que apaga coleções inteiras do Hive. Opera
/// diretamente sobre os data sources (e não sobre repositórios/casos de
/// uso de escrita) porque isso não é uma regra de negócio do domínio,
/// é limpeza de armazenamento local.
class ClearAppData {
  final BoxHiveDataSource boxDataSource;
  final ProductHiveDataSource productDataSource;
  final CategoryHiveDataSource categoryDataSource;
  final ProductTypeHiveDataSource productTypeDataSource;
  final UnitHiveDataSource unitDataSource;
  final TransactionHiveDataSource transactionDataSource;
  final BoxClosureHiveDataSource boxClosureDataSource;
  final PlanBoardHiveDataSource planBoardDataSource;
  final PlanItemHiveDataSource planItemDataSource;
  final ReportPresetRepository reportPresetRepository;
  final AppMetaStore metaStore;
  final CategoryRepository categoryRepository;
  final ProductTypeRepository productTypeRepository;
  final UnitRepository unitRepository;

  ClearAppData({
    required this.boxDataSource,
    required this.productDataSource,
    required this.categoryDataSource,
    required this.productTypeDataSource,
    required this.unitDataSource,
    required this.transactionDataSource,
    required this.boxClosureDataSource,
    required this.planBoardDataSource,
    required this.planItemDataSource,
    required this.reportPresetRepository,
    required this.metaStore,
    required this.categoryRepository,
    required this.productTypeRepository,
    required this.unitRepository,
  });

  Future<void> call(ClearDataScope scope) async {
    switch (scope) {
      case ClearDataScope.boxes:
        await _clearBoxes();
      case ClearDataScope.products:
        await productDataSource.clear();
      case ClearDataScope.history:
        await _clearHistory();
      case ClearDataScope.planning:
        await _clearPlanning();
      case ClearDataScope.reports:
        await reportPresetRepository.clear();
      case ClearDataScope.preferences:
        await _resetPreferences();
      case ClearDataScope.all:
        await _clearBoxes();
        await productDataSource.clear();
        await _clearHistory();
        await _clearPlanning();
        await reportPresetRepository.clear();
        await _resetPreferences();
        await _resetCatalogsAndReseed();
        await Get.find<AuthController>().logout();
    }
  }

  Future<void> _clearBoxes() async {
    await boxDataSource.clear();
    await transactionDataSource.clear();
    await boxClosureDataSource.clear();
  }

  Future<void> _clearHistory() async {
    await transactionDataSource.clear();
    await boxClosureDataSource.clear();
  }

  /// Preferências de aparência voltam ao padrão (tema do sistema).
  Future<void> _resetPreferences() async {
    await Get.find<ThemeController>().setMode(ThemeMode.system);
  }

  Future<void> _clearPlanning() async {
    await planItemDataSource.clear();
    await planBoardDataSource.clear();
  }

  Future<void> _resetCatalogsAndReseed() async {
    await categoryDataSource.clear();
    await productTypeDataSource.clear();
    await unitDataSource.clear();

    await metaStore.setDefaultsSeeded(false);
    await metaStore.setSchemaVersion(0);

    await SeedDefaults(
      metaStore: metaStore,
      categoryRepository: categoryRepository,
      productTypeRepository: productTypeRepository,
      unitRepository: unitRepository,
    ).run();
  }
}
