import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';

class CreateUnit {
  final UnitRepository repository;
  final QuotaGuard? quota;
  const CreateUnit(this.repository, {this.quota});

  Future<Result<UnitEntity>> call({
    required String name,
    required String abbreviation,
    bool allowsDecimal = false,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return Failure(ValidationFailure('units.unitNameRequired'.tr));
    }
    if (!Validators.isNotBlank(abbreviation)) {
      return Failure(ValidationFailure('units.unitAbbreviationRequired'.tr));
    }

    if (await quota?.ensureCanAdd(ResourceKey.units) case final limit?) return Failure(limit);

    final now = DateTime.now();
    final unit = UnitEntity(
      id: IdGenerator.generate(),
      name: name.trim(),
      abbreviation: abbreviation.trim(),
      allowsDecimal: allowsDecimal,
      createdAt: now,
      updatedAt: now,
    );

    final result = await repository.create(unit);
    return result.fold((_) => Success(unit), (f) => Failure(f));
  }
}
