import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';

class CreateBoxOutcome {
  final BoxEntity box;
  final bool hasDuplicateName;
  const CreateBoxOutcome({required this.box, required this.hasDuplicateName});
}

class CreateBox {
  final BoxRepository repository;
  const CreateBox(this.repository);

  Future<Result<CreateBoxOutcome>> call({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return const Failure(ValidationFailure('Nome da caixa é obrigatório.'));
    }
    if (!Validators.withinMaxLength(name, 40)) {
      return const Failure(ValidationFailure('Nome da caixa deve ter no máximo 40 caracteres.'));
    }

    final existingResult = await repository.getAll();
    if (existingResult.isFailure) {
      return Failure(existingResult.failureOrNull!);
    }

    final trimmedName = name.trim();
    final hasDuplicateName = existingResult.dataOrNull!
        .any((b) => b.name.trim().toLowerCase() == trimmedName.toLowerCase());

    final now = DateTime.now();
    final box = BoxEntity(
      id: IdGenerator.generate(),
      name: trimmedName,
      description: description,
      icon: icon,
      color: color,
      createdAt: now,
      updatedAt: now,
    );

    final result = await repository.create(box);
    return result.fold(
      (_) => Success(CreateBoxOutcome(box: box, hasDuplicateName: hasDuplicateName)),
      (f) => Failure(f),
    );
  }
}
