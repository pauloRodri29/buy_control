import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/auth/domain/entities/user_entity.dart';
import 'package:buy_control/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfile {
  final AuthRepository repository;
  const UpdateProfile(this.repository);

  Future<Result<UserEntity>> call(UserEntity user) async {
    if (!Validators.isNotBlank(user.name)) {
      return const Failure(ValidationFailure('Nome é obrigatório.'));
    }
    if (!Validators.isNotBlank(user.email) || !user.email.contains('@')) {
      return const Failure(ValidationFailure('Informe um e-mail válido.'));
    }
    return repository.updateProfile(user);
  }
}
