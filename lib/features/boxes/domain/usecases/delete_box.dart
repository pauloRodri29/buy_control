import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';

/// Exclusão lógica: a caixa some das listas de seleção, mas continua
/// resolvível para lançamentos antigos que a referenciam.
class DeleteBox {
  final BoxRepository repository;
  const DeleteBox(this.repository);

  Future<Result<void>> call(String id) async {
    final existing = await repository.getById(id);
    return existing.fold((box) {
      final now = DateTime.now();
      return repository.update(box.copyWith(deletedAt: now, updatedAt: now));
    }, (f) async => Failure(f));
  }
}
