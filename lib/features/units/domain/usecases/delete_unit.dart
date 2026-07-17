import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

/// Exclusão lógica: a unidade some das listas de seleção, mas continua
/// resolvível para lançamentos antigos que a referenciam.
class DeleteUnit {
  final UnitRepository repository;
  const DeleteUnit(this.repository);

  Future<Result<void>> call(String id) async {
    final existing = await repository.getById(id);
    return existing.fold((unit) {
      final now = DateTime.now();
      return repository.update(unit.copyWith(isActive: false, deletedAt: now, updatedAt: now));
    }, (f) async => Failure(f));
  }
}
