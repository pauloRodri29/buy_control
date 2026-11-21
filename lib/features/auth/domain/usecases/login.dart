import 'package:get/get.dart';
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
      return Failure(ValidationFailure('auth.enterValidEmail'.tr));
    }
    if (password.length < 4) {
      return Failure(ValidationFailure('auth.passwordMustHaveLeast4'.tr));
    }
    return repository.login(email: trimmedEmail, password: password);
  }
}
