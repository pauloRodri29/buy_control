import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/reports/data/repositories/report_preset_repository.dart';
import 'package:buy_control/features/settings/domain/usecases/clear_app_data.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:get/get.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ClearAppData(
        boxDataSource: BoxHiveDataSource(),
        productDataSource: ProductHiveDataSource(),
        categoryDataSource: CategoryHiveDataSource(),
        productTypeDataSource: ProductTypeHiveDataSource(),
        unitDataSource: UnitHiveDataSource(),
        transactionDataSource: TransactionHiveDataSource(),
        boxClosureDataSource: BoxClosureHiveDataSource(),
        reportPresetRepository: ReportPresetRepository(),
        metaStore: AppMetaStore(),
        categoryRepository: Get.find(),
        productTypeRepository: Get.find(),
        unitRepository: Get.find(),
      ),
    );
  }
}
