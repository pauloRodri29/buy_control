import 'package:buy_control/features/box_closures/presentation/controllers/box_closures_controller.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:get/get.dart';

class BoxClosuresBinding extends Bindings {
  final BoxEntity box;
  BoxClosuresBinding(this.box);

  @override
  void dependencies() {
    Get.lazyPut(
      () => BoxClosuresController(box: box, getBoxClosures: Get.find()),
      tag: box.id,
    );
  }
}
