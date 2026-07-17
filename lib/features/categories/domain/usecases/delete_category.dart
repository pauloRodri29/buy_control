import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';

/// Exclusão lógica: a categoria some das listas de seleção, mas continua
/// resolvível para lançamentos antigos que a referenciam.
class DeleteCategory {
  final CategoryRepository repository;
  const DeleteCategory(this.repository);

  Future<Result<void>> call(String id) async {
    final existing = await repository.getById(id);
    return existing.fold((category) {
      final now = DateTime.now();
      return repository.update(category.copyWith(isActive: false, deletedAt: now, updatedAt: now));
    }, (f) async => Failure(f));
  }
}
