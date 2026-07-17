import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';

class UpdateBox {
  final BoxRepository repository;
  const UpdateBox(this.repository);

  Future<Result<void>> call(BoxEntity box) async {
    if (!Validators.isNotBlank(box.name)) {
      return const Failure(ValidationFailure('Nome da caixa é obrigatório.'));
    }
    if (!Validators.withinMaxLength(box.name, 40)) {
      return const Failure(ValidationFailure('Nome da caixa deve ter no máximo 40 caracteres.'));
    }
    return repository.update(box);
  }
}
