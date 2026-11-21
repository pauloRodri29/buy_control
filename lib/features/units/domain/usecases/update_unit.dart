import 'package:get/get.dart';
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
      return Failure(ValidationFailure('units.unitNameRequired'.tr));
    }
    if (!Validators.isNotBlank(unit.abbreviation)) {
      return Failure(ValidationFailure('units.unitAbbreviationRequired'.tr));
    }
    return repository.update(unit);
  }
}
