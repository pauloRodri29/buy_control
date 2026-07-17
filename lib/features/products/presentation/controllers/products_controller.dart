import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/usecases/create_product.dart';
import 'package:buy_control/features/products/domain/usecases/delete_product.dart';
import 'package:buy_control/features/products/domain/usecases/search_products.dart';
import 'package:buy_control/features/products/domain/usecases/update_product.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:get/get.dart';

class ProductsController extends GetxController {
  final SearchProducts searchProducts;
  final GetCategories getCategories;
  final GetProductTypes getProductTypes;
  final GetUnits getUnits;
  final CreateProduct createProduct;
  final UpdateProduct updateProduct;
  final DeleteProduct deleteProduct;

  ProductsController({
    required this.searchProducts,
    required this.getCategories,
    required this.getProductTypes,
    required this.getUnits,
    required this.createProduct,
    required this.updateProduct,
    required this.deleteProduct,
  });

  ViewStatus status = ViewStatus.initial;
  List<ProductEntity> products = [];
  List<CategoryEntity> categories = [];
  List<ProductTypeEntity> productTypes = [];
  List<UnitEntity> units = [];
  String? errorMessage;

  String _query = '';
  String? _categoryId;
  String? get selectedCategoryId => _categoryId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final categoriesResult = await getCategories();
    categoriesResult.fold((data) => categories = data, (_) {});

    final productTypesResult = await getProductTypes();
    productTypesResult.fold((data) => productTypes = data, (_) {});

    final unitsResult = await getUnits();
    unitsResult.fold((data) => units = data, (_) {});

    await _search();
  }

  Future<void> _search() async {
    final result = await searchProducts(
      query: _query.trim().isEmpty ? null : _query,
      categoryId: _categoryId,
    );
    result.fold((data) {
      products = data;
      status = data.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }

  Future<void> search(String query) async {
    _query = query;
    await _search();
  }

  Future<void> filterByCategory(String? categoryId) async {
    _categoryId = categoryId;
    await _search();
  }

  String categoryName(String id) {
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return '—';
  }

  String productTypeName(String id) {
    for (final type in productTypes) {
      if (type.id == id) return type.name;
    }
    return '—';
  }

  String unitAbbreviation(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit.abbreviation;
    }
    return '—';
  }

  Future<String?> create({
    String? code,
    String? barcode,
    required String name,
    String? description,
    String? brand,
    required String categoryId,
    required String productTypeId,
    required String defaultUnitId,
    Money? referencePrice,
  }) async {
    final result = await createProduct(
      code: code,
      barcode: barcode,
      name: name,
      description: description,
      brand: brand,
      categoryId: categoryId,
      productTypeId: productTypeId,
      defaultUnitId: defaultUnitId,
      referencePrice: referencePrice,
    );
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<String?> edit(ProductEntity product) async {
    final result = await updateProduct(product);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<void> delete(String id) async {
    await deleteProduct(id);
    await load();
  }
}
