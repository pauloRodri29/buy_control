import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/product_types/data/models/product_type_model.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';

class ProductTypeMapper {
  static ProductTypeEntity toEntity(ProductTypeModel model) {
    return ProductTypeEntity(
      id: model.id,
      name: model.name,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static ProductTypeModel toModel(ProductTypeEntity entity) {
    return ProductTypeModel(
      id: entity.id,
      name: entity.name,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
