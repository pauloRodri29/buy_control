import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';

class CreateBoxOutcome {
  final BoxEntity box;
  final bool hasDuplicateName;
  const CreateBoxOutcome({required this.box, required this.hasDuplicateName});
}

class CreateBox {
  final BoxRepository repository;
  final QuotaGuard? quota;
  const CreateBox(this.repository, {this.quota});

  Future<Result<CreateBoxOutcome>> call({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return Failure(ValidationFailure('boxes.boxNameRequired'.tr));
    }
    if (!Validators.withinMaxLength(name, 40)) {
      return Failure(ValidationFailure('boxes.boxNameMustHaveMost'.tr));
    }

    if (await quota?.ensureCanAdd(ResourceKey.boxes) case final limit?) return Failure(limit);

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
