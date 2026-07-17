import 'package:buy_control/features/boxes/domain/usecases/archive_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/create_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/delete_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/update_box.dart';
import 'package:buy_control/features/boxes/presentation/controllers/boxes_controller.dart';
import 'package:get/get.dart';

class BoxesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateBox(Get.find()));
    Get.lazyPut(() => UpdateBox(Get.find()));
    Get.lazyPut(() => DeleteBox(Get.find()));
    Get.lazyPut(() => ArchiveBox(Get.find()));
    Get.lazyPut(() => BoxesController(
          getBoxes: Get.find(),
          getBoxSummary: Get.find(),
          createBox: Get.find(),
          updateBox: Get.find(),
          deleteBox: Get.find(),
          archiveBox: Get.find(),
        ));
  }
}
