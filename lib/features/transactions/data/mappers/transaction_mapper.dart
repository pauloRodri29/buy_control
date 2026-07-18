import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/transactions/data/mappers/transaction_item_mapper.dart';
import 'package:buy_control/features/transactions/data/models/transaction_model.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';

class TransactionMapper {
  static TransactionEntity toEntity(TransactionModel model) {
    return TransactionEntity(
      id: model.id,
      boxId: model.boxId,
      title: model.title,
      occurredAt: model.occurredAt,
      notes: model.notes,
      discount: Money(model.discountCents),
      additionalCost: Money(model.additionalCostCents),
      items: model.itemModels.map(TransactionItemMapper.toEntity).toList(),
      closureId: model.closureId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static TransactionModel toModel(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      boxId: entity.boxId,
      title: entity.title,
      occurredAt: entity.occurredAt,
      notes: entity.notes,
      discountCents: entity.discount.cents,
      additionalCostCents: entity.additionalCost.cents,
      items: entity.items
          .map((item) => TransactionItemMapper.toModel(item).toMap())
          .toList(),
      closureId: entity.closureId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
