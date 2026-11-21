import 'package:get/get.dart';
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
      return Failure(ValidationFailure('auth.nameRequired'.tr));
    }
    if (!Validators.isNotBlank(user.email) || !user.email.contains('@')) {
      return Failure(ValidationFailure('auth.enterValidEmail'.tr));
    }
    return repository.updateProfile(user);
  }
}
