import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';

class ArchiveBox {
  final BoxRepository repository;
  const ArchiveBox(this.repository);

  Future<Result<void>> call(String id, {bool archived = true}) async {
    final existing = await repository.getById(id);
    return existing.fold((box) {
      final now = DateTime.now();
      return repository.update(box.copyWith(isArchived: archived, updatedAt: now));
    }, (f) async => Failure(f));
  }
}
