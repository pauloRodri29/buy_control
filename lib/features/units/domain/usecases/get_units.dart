import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

class GetUnits {
  final UnitRepository repository;
  const GetUnits(this.repository);

  Future<Result<List<UnitEntity>>> call({bool includeInactive = false}) {
    return repository.getAll(includeInactive: includeInactive);
  }
}
