import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/auth/domain/entities/user_entity.dart';
import 'package:buy_control/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;
  const GetCurrentUser(this.repository);

  Future<Result<UserEntity?>> call() => repository.currentUser();
}
