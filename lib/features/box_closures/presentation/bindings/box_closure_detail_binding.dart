import 'package:buy_control/features/box_closures/domain/usecases/get_box_closure_details.dart';
import 'package:buy_control/features/box_closures/domain/usecases/reopen_box_closure.dart';
import 'package:buy_control/features/box_closures/presentation/controllers/box_closure_detail_controller.dart';
import 'package:get/get.dart';

class BoxClosureDetailBinding extends Bindings {
  final String closureId;
  BoxClosureDetailBinding(this.closureId);

  @override
  void dependencies() {
    Get.lazyPut(() => GetBoxClosureDetails(closureRepository: Get.find(), transactionRepository: Get.find()));
    Get.lazyPut(() => ReopenBoxClosure(closureRepository: Get.find(), transactionRepository: Get.find()));
    Get.lazyPut(
      () => BoxClosureDetailController(
        closureId: closureId,
        getBoxClosureDetails: Get.find(),
        reopenBoxClosure: Get.find(),
      ),
      tag: closureId,
    );
  }
}
