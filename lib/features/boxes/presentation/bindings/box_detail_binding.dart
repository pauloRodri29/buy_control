import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/presentation/controllers/box_detail_controller.dart';
import 'package:buy_control/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:buy_control/features/transactions/domain/usecases/search_transactions.dart';
import 'package:get/get.dart';

class BoxDetailBinding extends Bindings {
  final BoxEntity box;
  BoxDetailBinding(this.box);

  @override
  void dependencies() {
    Get.lazyPut(() => SearchTransactions(Get.find()));
    Get.lazyPut(() => DeleteTransaction(Get.find()));
    Get.lazyPut(
      () => BoxDetailController(
        box: box,
        getBoxSummary: Get.find(),
        getTransactionsByBox: Get.find(),
        searchTransactions: Get.find(),
        deleteTransaction: Get.find(),
      ),
      tag: box.id,
    );
  }
}
