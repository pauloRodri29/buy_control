import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/data/safety_snapshot_store.dart';
import 'package:buy_control/features/backup/domain/usecases/export_backup.dart';
import 'package:buy_control/features/backup/domain/usecases/import_backup.dart';
import 'package:buy_control/features/backup/presentation/controllers/backup_controller.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/planning/data/datasources/local/plan_hive_data_sources.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class BackupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BackupController(
        exportBackup: ExportBackup(
          boxDataSource: BoxHiveDataSource(),
          productDataSource: ProductHiveDataSource(),
          categoryDataSource: CategoryHiveDataSource(),
          productTypeDataSource: ProductTypeHiveDataSource(),
          unitDataSource: UnitHiveDataSource(),
          transactionDataSource: TransactionHiveDataSource(),
          boxClosureDataSource: BoxClosureHiveDataSource(),
          planBoardDataSource: PlanBoardHiveDataSource(),
          planItemDataSource: PlanItemHiveDataSource(),
        ),
        importBackup: ImportBackup(
          boxDataSource: BoxHiveDataSource(),
          productDataSource: ProductHiveDataSource(),
          categoryDataSource: CategoryHiveDataSource(),
          productTypeDataSource: ProductTypeHiveDataSource(),
          unitDataSource: UnitHiveDataSource(),
          transactionDataSource: TransactionHiveDataSource(),
          boxClosureDataSource: BoxClosureHiveDataSource(),
          planBoardDataSource: PlanBoardHiveDataSource(),
          planItemDataSource: PlanItemHiveDataSource(),
        ),
        settings: BackupSettingsStore(),
        safety: SafetySnapshotStore(),
        httpClient: http.Client(),
      ),
    );
  }
}
