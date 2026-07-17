import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';

class UpdateCategory {
  final CategoryRepository repository;
  const UpdateCategory(this.repository);

  Future<Result<void>> call(CategoryEntity category) async {
    if (!Validators.isNotBlank(category.name)) {
      return const Failure(ValidationFailure('Nome da categoria é obrigatório.'));
    }
    return repository.update(category);
  }
}
