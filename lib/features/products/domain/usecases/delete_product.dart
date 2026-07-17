import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

/// Exclusão lógica: produtos podem estar referenciados por itens de
/// transações históricas como snapshot, então nunca são removidos fisicamente.
class DeleteProduct {
  final ProductRepository repository;
  const DeleteProduct(this.repository);

  Future<Result<void>> call(String id) async {
    final existing = await repository.getById(id);
    return existing.fold((product) {
      final now = DateTime.now();
      return repository.update(product.copyWith(isActive: false, deletedAt: now, updatedAt: now));
    }, (f) async => Failure(f));
  }
}
