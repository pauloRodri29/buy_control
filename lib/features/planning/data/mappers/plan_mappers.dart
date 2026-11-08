import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/planning/data/models/plan_board_model.dart';
import 'package:buy_control/features/planning/data/models/plan_item_model.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';

class PlanBoardMapper {
  static PlanBoardEntity toEntity(PlanBoardModel model) {
    return PlanBoardEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      goal: model.goalCents == null ? null : Money(model.goalCents!),
      targetDate: model.targetDate,
      isArchived: model.isArchived,
      closedAt: model.closedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static PlanBoardModel toModel(PlanBoardEntity entity) {
    return PlanBoardModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      goalCents: entity.goal?.cents,
      targetDate: entity.targetDate,
      isArchived: entity.isArchived,
      closedAt: entity.closedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}

class PlanItemMapper {
  static PlanItemEntity toEntity(PlanItemModel model) {
    return PlanItemEntity(
      id: model.id,
      boardId: model.boardId,
      title: model.title,
      description: model.description,
      estimatedValue: model.estimatedValueCents == null ? null : Money(model.estimatedValueCents!),
      position: model.position,
      isPurchased: model.isPurchased,
      purchasedAt: model.purchasedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static PlanItemModel toModel(PlanItemEntity entity) {
    return PlanItemModel(
      id: entity.id,
      boardId: entity.boardId,
      title: entity.title,
      description: entity.description,
      estimatedValueCents: entity.estimatedValue?.cents,
      position: entity.position,
      isPurchased: entity.isPurchased,
      purchasedAt: entity.purchasedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
