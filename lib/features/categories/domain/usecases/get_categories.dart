import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';

class GetCategories {
  final CategoryRepository repository;
  const GetCategories(this.repository);

  Future<Result<List<CategoryEntity>>> call({bool includeInactive = false}) {
    return repository.getAll(includeInactive: includeInactive);
  }
}
