import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';

abstract interface class UnitRepository {
  Future<Result<List<UnitEntity>>> getAll({bool includeInactive = false});
  Future<Result<UnitEntity>> getById(String id);
  Future<Result<void>> create(UnitEntity unit);
  Future<Result<void>> update(UnitEntity unit);
  Future<Result<void>> delete(String id);
}
