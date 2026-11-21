import 'package:buy_control/features/planning/domain/usecases/plan_board_usecases.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_usecases.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:get/get.dart';

/// Os repositórios do Planejamento ficam no `InitialBinding`, pois também
/// são lidos pelos Relatórios.
class PlanningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GetPlanBoards(Get.find()));
    Get.lazyPut(() => CreatePlanBoard(Get.find()));
    Get.lazyPut(() => CreatePlanBoardFromTemplate(createBoard: Get.find(), itemRepository: Get.find()));
    Get.lazyPut(() => UpdatePlanBoard(Get.find()));
    Get.lazyPut(() => DeletePlanBoard(boardRepository: Get.find(), itemRepository: Get.find()));
    Get.lazyPut(() => FinishPlanBoard(boardRepository: Get.find(), itemRepository: Get.find()));
    Get.lazyPut(() => GetPlanItems(Get.find()));
    Get.lazyPut(() => CreatePlanItem(Get.find()));
    Get.lazyPut(() => UpdatePlanItem(Get.find()));
    Get.lazyPut(() => DeletePlanItem(Get.find()));
    Get.lazyPut(() => TogglePlanItemPurchased(Get.find()));
    Get.lazyPut(() => MovePlanItem(Get.find()));
    Get.lazyPut(() => SendPendingItemToBoard(Get.find()));

    Get.lazyPut(() => PlanningController(
          getBoards: Get.find(),
          createBoard: Get.find(),
          createBoardFromTemplate: Get.find(),
          updateBoard: Get.find(),
          deleteBoard: Get.find(),
          finishBoard: Get.find(),
          getItems: Get.find(),
          createItem: Get.find(),
          updateItem: Get.find(),
          deleteItem: Get.find(),
          togglePurchased: Get.find(),
          moveItem: Get.find(),
          sendPendingToBoard: Get.find(),
        ));
  }
}
