import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/usecases/create_product_type.dart';
import 'package:buy_control/features/product_types/domain/usecases/delete_product_type.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/features/product_types/domain/usecases/update_product_type.dart';
import 'package:get/get.dart';

class ProductTypesController extends GetxController {
  final GetProductTypes getProductTypes;
  final CreateProductType createProductType;
  final UpdateProductType updateProductType;
  final DeleteProductType deleteProductType;

  ProductTypesController({
    required this.getProductTypes,
    required this.createProductType,
    required this.updateProductType,
    required this.deleteProductType,
  });

  ViewStatus status = ViewStatus.initial;
  List<ProductTypeEntity> productTypes = [];
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final result = await getProductTypes();
    result.fold((data) {
      productTypes = data;
      status = data.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }

  Future<String?> create({required String name}) async {
    final result = await createProductType(name: name);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<String?> edit(ProductTypeEntity productType) async {
    final result = await updateProductType(productType);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<void> delete(String id) async {
    await deleteProductType(id);
    await load();
  }
}
