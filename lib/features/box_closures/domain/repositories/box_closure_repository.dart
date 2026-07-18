import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';

abstract interface class BoxClosureRepository {
  Future<Result<List<BoxClosureEntity>>> getAll({String? boxId, bool includeDeleted = false});
  Future<Result<BoxClosureEntity>> getById(String id);
  Future<Result<void>> create(BoxClosureEntity closure);
  Future<Result<void>> update(BoxClosureEntity closure);
  Future<Result<void>> delete(String id);
}
