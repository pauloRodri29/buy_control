import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/auth/data/mappers/user_mapper.dart';
import 'package:buy_control/features/auth/data/models/user_model.dart';
import 'package:buy_control/features/auth/domain/entities/user_entity.dart';
import 'package:buy_control/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Autenticação "fake": não valida senha contra nada externo, apenas guarda
/// uma sessão local no Hive. Cada usuário fica salvo sob a chave do seu
/// próprio id no box `authSession`; a chave [_currentUserIdKey] guarda quem
/// está logado agora, permitindo sessão persistente entre aberturas do app.
class FakeAuthRepository implements AuthRepository {
  static const _currentUserIdKey = 'currentUserId';

  Box get _box => Hive.box(HiveBoxRegistry.authSession);

  UserModel? _findByEmail(String email) {
    for (final key in _box.keys) {
      if (key == _currentUserIdKey) continue;
      final raw = _box.get(key);
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['email'] == email) return UserModel.fromMap(map);
    }
    return null;
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return local;
    return local[0].toUpperCase() + local.substring(1);
  }

  @override
  Future<Result<UserEntity>> login({required String email, required String password}) async {
    try {
      final now = DateTime.now();
      final existing = _findByEmail(email);

      final model = existing != null
          ? UserModel(
              id: existing.id,
              name: existing.name,
              email: existing.email,
              avatarUrl: existing.avatarUrl,
              createdAt: existing.createdAt,
              updatedAt: now,
              deletedAt: existing.deletedAt,
              syncStatus: existing.syncStatus,
              version: existing.version,
            )
          : UserModel(
              id: IdGenerator.generate(),
              name: _nameFromEmail(email),
              email: email,
              createdAt: now,
              updatedAt: now,
              syncStatus: SyncStatus.synced.name,
              version: 1,
            );

      await _box.put(model.id, model.toMap());
      await _box.put(_currentUserIdKey, model.id);
      return Success(UserMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _box.delete(_currentUserIdKey);
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<UserEntity?>> currentUser() async {
    try {
      final id = _box.get(_currentUserIdKey) as String?;
      if (id == null) return const Success(null);

      final raw = _box.get(id);
      if (raw is! Map) return const Success(null);

      final model = UserModel.fromMap(Map<String, dynamic>.from(raw));
      return Success(UserMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<UserEntity>> updateProfile(UserEntity user) async {
    try {
      final model = UserMapper.toModel(user);
      await _box.put(model.id, model.toMap());
      return Success(user);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }
}
