import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:buy_control/features/units/data/repositories/local_unit_repository.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';
import 'package:buy_control/features/units/domain/usecases/create_unit.dart';
import 'package:buy_control/features/units/domain/usecases/delete_unit.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:buy_control/features/units/domain/usecases/update_unit.dart';
import 'package:buy_control/features/units/presentation/controllers/units_controller.dart';
import 'package:get/get.dart';

class UnitsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UnitHiveDataSource>(() => UnitHiveDataSource());
    Get.lazyPut<UnitRepository>(() => LocalUnitRepository(localDataSource: Get.find()));
    Get.lazyPut(() => GetUnits(Get.find()));
    Get.lazyPut(() => CreateUnit(Get.find()));
    Get.lazyPut(() => UpdateUnit(Get.find()));
    Get.lazyPut(() => DeleteUnit(Get.find()));
    Get.lazyPut(() => UnitsController(
          getUnits: Get.find(),
          createUnit: Get.find(),
          updateUnit: Get.find(),
          deleteUnit: Get.find(),
        ));
  }
}
