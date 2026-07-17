import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

class CreateUnit {
  final UnitRepository repository;
  const CreateUnit(this.repository);

  Future<Result<UnitEntity>> call({
    required String name,
    required String abbreviation,
    bool allowsDecimal = false,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return const Failure(ValidationFailure('Nome da unidade é obrigatório.'));
    }
    if (!Validators.isNotBlank(abbreviation)) {
      return const Failure(ValidationFailure('Abreviação da unidade é obrigatória.'));
    }

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
