import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

class UpdateUnit {
  final UnitRepository repository;
  const UpdateUnit(this.repository);

  Future<Result<void>> call(UnitEntity unit) async {
    if (!Validators.isNotBlank(unit.name)) {
      return const Failure(ValidationFailure('Nome da unidade é obrigatório.'));
    }
    if (!Validators.isNotBlank(unit.abbreviation)) {
      return const Failure(ValidationFailure('Abreviação da unidade é obrigatória.'));
    }
    return repository.update(unit);
  }
}
