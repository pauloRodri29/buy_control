import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_charts.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:buy_control/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:get/get.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GetDashboardSummary(boxRepository: Get.find(), transactionRepository: Get.find()));
    Get.lazyPut(() => GetDashboardCharts(
          boxRepository: Get.find(),
          transactionRepository: Get.find(),
          categoryRepository: Get.find(),
        ));
    Get.lazyPut(() => DashboardController(
          getDashboardSummary: Get.find(),
          getDashboardCharts: Get.find(),
          getBoxes: Get.find(),
          getCategories: Get.find(),
        ));
  }
}
