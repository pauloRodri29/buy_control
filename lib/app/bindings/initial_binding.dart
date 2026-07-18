import 'package:buy_control/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:buy_control/features/auth/domain/repositories/auth_repository.dart';
import 'package:buy_control/features/auth/domain/usecases/get_current_user.dart';
import 'package:buy_control/features/auth/domain/usecases/login.dart';
import 'package:buy_control/features/auth/domain/usecases/logout.dart';
import 'package:buy_control/features/auth/domain/usecases/update_profile.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/box_closures/data/repositories/local_box_closure_repository.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closures.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/repositories/local_box_repository.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_by_id.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_summary.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_boxes.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/categories/data/repositories/local_category_repository.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/product_types/data/repositories/local_product_type_repository.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/products/data/repositories/local_product_repository.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/products/domain/usecases/get_products.dart';
import 'package:buy_control/features/products/domain/usecases/get_products_by_category.dart';
import 'package:buy_control/features/products/domain/usecases/search_products.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/repositories/local_transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/get_transaction_details.dart';
import 'package:buy_control/features/transactions/domain/usecases/get_transactions_by_box.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:buy_control/features/units/data/repositories/local_unit_repository.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:get/get.dart';

/// Registrado uma única vez em `main.dart` (`initialBinding`), como
/// singletons permanentes. Reúne os repositórios (cada um usado por mais
/// de uma feature) e os casos de uso de leitura mais reaproveitados, para
/// que qualquer controller consiga `Get.find()` sem depender da ordem de
/// navegação entre abas. Casos de uso de escrita (Create/Update/Delete) e
/// os controllers continuam registrados nos bindings de cada feature.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BoxRepository>(LocalBoxRepository(localDataSource: BoxHiveDataSource()), permanent: true);
    Get.put<BoxClosureRepository>(
      LocalBoxClosureRepository(localDataSource: BoxClosureHiveDataSource()),
      permanent: true,
    );
    Get.put<ProductRepository>(LocalProductRepository(localDataSource: ProductHiveDataSource()), permanent: true);
    Get.put<TransactionRepository>(
      LocalTransactionRepository(localDataSource: TransactionHiveDataSource()),
      permanent: true,
    );
    Get.put<CategoryRepository>(LocalCategoryRepository(localDataSource: CategoryHiveDataSource()), permanent: true);
    Get.put<ProductTypeRepository>(
      LocalProductTypeRepository(localDataSource: ProductTypeHiveDataSource()),
      permanent: true,
    );
    Get.put<UnitRepository>(LocalUnitRepository(localDataSource: UnitHiveDataSource()), permanent: true);

    Get.put(GetBoxes(Get.find()), permanent: true);
    Get.put(GetBoxById(Get.find()), permanent: true);
    Get.put(GetBoxSummary(boxRepository: Get.find(), transactionRepository: Get.find()), permanent: true);
    Get.put(GetProducts(Get.find()), permanent: true);
    Get.put(SearchProducts(Get.find()), permanent: true);
    Get.put(GetProductsByCategory(Get.find()), permanent: true);
    Get.put(GetCategories(Get.find()), permanent: true);
    Get.put(GetProductTypes(Get.find()), permanent: true);
    Get.put(GetUnits(Get.find()), permanent: true);
    Get.put(GetTransactionsByBox(Get.find()), permanent: true);
    Get.put(GetTransactionDetails(Get.find()), permanent: true);
    Get.put(GetBoxClosures(Get.find()), permanent: true);

    Get.put<AuthRepository>(FakeAuthRepository(), permanent: true);
    Get.put(Login(Get.find()), permanent: true);
    Get.put(Logout(Get.find()), permanent: true);
    Get.put(GetCurrentUser(Get.find()), permanent: true);
    Get.put(UpdateProfile(Get.find()), permanent: true);
    Get.put(
      AuthController(
        login: Get.find(),
        logout: Get.find(),
        getCurrentUser: Get.find(),
        updateProfile: Get.find(),
      ),
      permanent: true,
    );
  }
}
