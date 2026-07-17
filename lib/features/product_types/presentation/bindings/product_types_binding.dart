import 'package:buy_control/features/product_types/domain/usecases/create_product_type.dart';
import 'package:buy_control/features/product_types/domain/usecases/delete_product_type.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/features/product_types/domain/usecases/update_product_type.dart';
import 'package:buy_control/features/product_types/presentation/controllers/product_types_controller.dart';
import 'package:get/get.dart';

class ProductTypesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateProductType(Get.find()));
    Get.lazyPut(() => UpdateProductType(Get.find()));
    Get.lazyPut(() => DeleteProductType(Get.find()));
    Get.lazyPut(() => ProductTypesController(
          getProductTypes: Get.find<GetProductTypes>(),
          createProductType: Get.find(),
          updateProductType: Get.find(),
          deleteProductType: Get.find(),
        ));
  }
}
