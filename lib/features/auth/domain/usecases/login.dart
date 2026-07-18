import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/auth/domain/entities/user_entity.dart';
import 'package:buy_control/features/auth/domain/repositories/auth_repository.dart';

class Login {
  final AuthRepository repository;
  const Login(this.repository);

  Future<Result<UserEntity>> call({required String email, required String password}) async {
    final trimmedEmail = email.trim();
    if (!Validators.isNotBlank(trimmedEmail) || !trimmedEmail.contains('@')) {
      return const Failure(ValidationFailure('Informe um e-mail válido.'));
    }
    if (password.length < 4) {
      return const Failure(ValidationFailure('A senha deve ter ao menos 4 caracteres.'));
    }
    return repository.login(email: trimmedEmail, password: password);
  }
}
