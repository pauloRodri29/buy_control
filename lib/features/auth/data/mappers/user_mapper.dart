import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/auth/data/models/user_model.dart';
import 'package:buy_control/features/auth/domain/entities/user_entity.dart';

class UserMapper {
  static UserEntity toEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      name: model.name,
      email: model.email,
      avatarUrl: model.avatarUrl,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static UserModel toModel(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      avatarUrl: entity.avatarUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
