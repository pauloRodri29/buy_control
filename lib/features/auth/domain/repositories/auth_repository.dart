import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/auth/domain/entities/user_entity.dart';

/// Contrato de autenticação. A implementação de hoje (`FakeAuthRepository`)
/// valida localmente e guarda a sessão no Hive; no futuro, uma
/// `ApiAuthRepository` implementa a mesma interface sem exigir mudanças
/// em telas ou casos de uso.
abstract interface class AuthRepository {
  Future<Result<UserEntity>> login({required String email, required String password});
  Future<Result<void>> logout();
  Future<Result<UserEntity?>> currentUser();
  Future<Result<UserEntity>> updateProfile(UserEntity user);
}
