import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';

class CreateCategory {
  final CategoryRepository repository;
  const CreateCategory(this.repository);

  Future<Result<CategoryEntity>> call({
    required String name,
    String? icon,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return const Failure(ValidationFailure('Nome da categoria é obrigatório.'));
    }

    final now = DateTime.now();
    final category = CategoryEntity(
      id: IdGenerator.generate(),
      name: name.trim(),
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );

    final result = await repository.create(category);
    return result.fold((_) => Success(category), (f) => Failure(f));
  }
}
