import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/features/products/domain/usecases/create_product.dart';
import 'package:buy_control/features/products/domain/usecases/delete_product.dart';
import 'package:buy_control/features/products/domain/usecases/search_products.dart';
import 'package:buy_control/features/products/domain/usecases/update_product.dart';
import 'package:buy_control/features/products/presentation/controllers/products_controller.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:get/get.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateProduct(Get.find()));
    Get.lazyPut(() => UpdateProduct(Get.find()));
    Get.lazyPut(() => DeleteProduct(Get.find()));
    Get.lazyPut(() => ProductsController(
          searchProducts: Get.find<SearchProducts>(),
          getCategories: Get.find<GetCategories>(),
          getProductTypes: Get.find<GetProductTypes>(),
          getUnits: Get.find<GetUnits>(),
          createProduct: Get.find(),
          updateProduct: Get.find(),
          deleteProduct: Get.find(),
        ));
  }
}
