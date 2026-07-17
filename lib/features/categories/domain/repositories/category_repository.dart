import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';

abstract interface class CategoryRepository {
  Future<Result<List<CategoryEntity>>> getAll({bool includeInactive = false});
  Future<Result<CategoryEntity>> getById(String id);
  Future<Result<void>> create(CategoryEntity category);
  Future<Result<void>> update(CategoryEntity category);
  Future<Result<void>> delete(String id);
}
