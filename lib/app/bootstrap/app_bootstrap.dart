import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/database/legacy_data_reader.dart';
import 'package:buy_control/app/bootstrap/migration_runner.dart';
import 'package:buy_control/app/bootstrap/seed_defaults.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/repositories/local_box_repository.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/categories/data/repositories/local_category_repository.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/product_types/data/repositories/local_product_type_repository.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/repositories/local_transaction_repository.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:buy_control/features/units/data/repositories/local_unit_repository.dart';

/// Ponto único de inicialização do app: abre o Hive, roda a migração dos
/// dados legados e semeia os catálogos padrão. Chamado uma vez em `main()`,
/// antes do `runApp`.
class AppBootstrap {
  static Future<void> run() async {
    await HiveBoxRegistry.initHive();

    final metaStore = AppMetaStore();

    final boxRepository = LocalBoxRepository(localDataSource: BoxHiveDataSource());
    final transactionRepository = LocalTransactionRepository(localDataSource: TransactionHiveDataSource());
    final unitRepository = LocalUnitRepository(localDataSource: UnitHiveDataSource());
    final categoryRepository = LocalCategoryRepository(localDataSource: CategoryHiveDataSource());
    final productTypeRepository = LocalProductTypeRepository(localDataSource: ProductTypeHiveDataSource());

    await SeedDefaults(
      metaStore: metaStore,
      categoryRepository: categoryRepository,
      productTypeRepository: productTypeRepository,
      unitRepository: unitRepository,
    ).run();

    await MigrationRunner(
      metaStore: metaStore,
      legacyDataReader: LegacyDataReader(),
      boxRepository: boxRepository,
      transactionRepository: transactionRepository,
      unitRepository: unitRepository,
    ).run();
  }
}
