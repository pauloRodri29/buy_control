import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/box_closures/data/models/box_closure_model.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';

class BoxClosureMapper {
  static BoxClosureEntity toEntity(BoxClosureModel model) {
    return BoxClosureEntity(
      id: model.id,
      boxId: model.boxId,
      boxNameSnapshot: model.boxNameSnapshot,
      closedAt: model.closedAt,
      notes: model.notes,
      total: Money(model.totalCents),
      transactionCount: model.transactionCount,
      itemCount: model.itemCount,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static BoxClosureModel toModel(BoxClosureEntity entity) {
    return BoxClosureModel(
      id: entity.id,
      boxId: entity.boxId,
      boxNameSnapshot: entity.boxNameSnapshot,
      closedAt: entity.closedAt,
      notes: entity.notes,
      totalCents: entity.total.cents,
      transactionCount: entity.transactionCount,
      itemCount: entity.itemCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
