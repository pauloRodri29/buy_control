import 'package:buy_control/features/categories/domain/usecases/create_category.dart';
import 'package:buy_control/features/categories/domain/usecases/delete_category.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/categories/domain/usecases/update_category.dart';
import 'package:buy_control/features/categories/presentation/controllers/categories_controller.dart';
import 'package:get/get.dart';

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateCategory(Get.find()));
    Get.lazyPut(() => UpdateCategory(Get.find()));
    Get.lazyPut(() => DeleteCategory(Get.find()));
    Get.lazyPut(() => CategoriesController(
          getCategories: Get.find<GetCategories>(),
          createCategory: Get.find(),
          updateCategory: Get.find(),
          deleteCategory: Get.find(),
        ));
  }
}
