import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/reports/data/exporters/app_report_exporter.dart';
import 'package:buy_control/features/reports/data/repositories/report_preset_repository.dart';
import 'package:buy_control/features/reports/domain/repositories/report_exporter.dart';
import 'package:buy_control/features/reports/domain/usecases/export_report.dart';
import 'package:buy_control/features/reports/domain/usecases/get_boxes_totals.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:buy_control/features/reports/presentation/controllers/reports_controller.dart';
import 'package:get/get.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GetBoxesTotals(boxRepository: Get.find(), transactionRepository: Get.find()));
    Get.lazyPut(
      () => GetConsolidatedReport(
        boxRepository: Get.find(),
        transactionRepository: Get.find(),
        categoryRepository: Get.find(),
        productRepository: Get.find(),
        // Tipo explícito: os parâmetros são anuláveis, e sem ele o GetX
        // procuraria por "PlanBoardRepository?".
        planBoardRepository: Get.find<PlanBoardRepository>(),
        planItemRepository: Get.find<PlanItemRepository>(),
      ),
    );
    Get.lazyPut<ReportExporter>(() => const AppReportExporter());
    Get.lazyPut(() => ExportReport(Get.find()));
    Get.lazyPut(() => ReportPresetRepository());
    Get.lazyPut(
      () => ReportsController(
        getBoxesTotals: Get.find(),
        getConsolidatedReport: Get.find(),
        exportReport: Get.find(),
        getBoxes: Get.find(),
        getCategories: Get.find(),
        getProductTypes: Get.find(),
        getProducts: Get.find(),
        reportPresetRepository: Get.find(),
      ),
    );
  }
}
