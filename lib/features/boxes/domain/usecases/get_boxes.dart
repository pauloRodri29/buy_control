import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';

class GetBoxes {
  final BoxRepository repository;
  const GetBoxes(this.repository);

  Future<Result<List<BoxEntity>>> call({bool includeArchived = false, bool includeDeleted = false}) async {
    final result = await repository.getAll(includeArchived: includeArchived, includeDeleted: includeDeleted);
    return result.fold((boxes) {
      final sorted = List<BoxEntity>.from(boxes)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Success(sorted);
    }, (f) => Failure(f));
  }
}
