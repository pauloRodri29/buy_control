import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';

/// Exclusão lógica: o tipo de produto some das listas de seleção, mas
/// continua resolvível para lançamentos antigos que o referenciam.
class DeleteProductType {
  final ProductTypeRepository repository;
  const DeleteProductType(this.repository);

  Future<Result<void>> call(String id) async {
    final existing = await repository.getById(id);
    return existing.fold((productType) {
      final now = DateTime.now();
      return repository.update(productType.copyWith(isActive: false, deletedAt: now, updatedAt: now));
    }, (f) async => Failure(f));
  }
}
