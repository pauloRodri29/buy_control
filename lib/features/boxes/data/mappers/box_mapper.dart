import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/boxes/data/models/box_model.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';

class BoxMapper {
  static BoxEntity toEntity(BoxModel model) {
    return BoxEntity(
      id: model.id,
      name: model.name,
      description: model.description,
      icon: model.icon,
      color: model.color,
      isArchived: model.isArchived,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static BoxModel toModel(BoxEntity entity) {
    return BoxModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      color: entity.color,
      isArchived: entity.isArchived,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
