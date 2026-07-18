import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/auth/domain/repositories/auth_repository.dart';

class Logout {
  final AuthRepository repository;
  const Logout(this.repository);

  Future<Result<void>> call() => repository.logout();
}
