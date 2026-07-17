import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';

abstract interface class BoxRepository {
  Future<Result<List<BoxEntity>>> getAll({bool includeArchived = false, bool includeDeleted = false});
  Future<Result<BoxEntity>> getById(String id);
  Future<Result<void>> create(BoxEntity box);
  Future<Result<void>> update(BoxEntity box);
  Future<Result<void>> delete(String id);
}
