import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/units/data/models/unit_model.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';

class UnitMapper {
  static UnitEntity toEntity(UnitModel model) {
    return UnitEntity(
      id: model.id,
      name: model.name,
      abbreviation: model.abbreviation,
      allowsDecimal: model.allowsDecimal,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static UnitModel toModel(UnitEntity entity) {
    return UnitModel(
      id: entity.id,
      name: entity.name,
      abbreviation: entity.abbreviation,
      allowsDecimal: entity.allowsDecimal,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
