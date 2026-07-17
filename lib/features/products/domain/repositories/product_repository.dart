import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';

abstract interface class ProductRepository {
  Future<Result<List<ProductEntity>>> getAll({bool includeInactive = false});
  Future<Result<ProductEntity>> getById(String id);
  Future<Result<void>> create(ProductEntity product);
  Future<Result<void>> update(ProductEntity product);
  Future<Result<void>> delete(String id);
}
