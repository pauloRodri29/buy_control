import 'package:buy_control/core/sync/syncable.dart';

/// Usuário autenticado. Estende `SyncableFields` propositalmente — mesmo
/// com autenticação fake e um único usuário hoje, isso já deixa a
/// entidade pronta para sincronizar com uma futura API multiusuário.
class UserEntity extends SyncableFields {
  final String name;
  final String email;
  final String? avatarUrl;

  const UserEntity({
    required super.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  UserEntity copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
