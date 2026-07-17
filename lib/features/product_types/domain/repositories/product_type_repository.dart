import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';

abstract interface class ProductTypeRepository {
  Future<Result<List<ProductTypeEntity>>> getAll({bool includeInactive = false});
  Future<Result<ProductTypeEntity>> getById(String id);
  Future<Result<void>> create(ProductTypeEntity productType);
  Future<Result<void>> update(ProductTypeEntity productType);
  Future<Result<void>> delete(String id);
}
