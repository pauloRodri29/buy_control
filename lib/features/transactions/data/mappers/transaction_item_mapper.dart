import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/data/models/transaction_item_model.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';

class TransactionItemMapper {
  static TransactionItemEntity toEntity(TransactionItemModel model) {
    return TransactionItemEntity(
      id: model.id,
      transactionId: model.transactionId,
      productId: model.productId,
      nameSnapshot: model.nameSnapshot,
      categoryId: model.categoryId,
      unitId: model.unitId,
      quantity: model.quantity,
      unitPrice: Money(model.unitPriceCents),
      discount: Money(model.discountCents),
      additionalCost: Money(model.additionalCostCents),
    );
  }

  static TransactionItemModel toModel(TransactionItemEntity entity) {
    return TransactionItemModel(
      id: entity.id,
      transactionId: entity.transactionId,
      productId: entity.productId,
      nameSnapshot: entity.nameSnapshot,
      categoryId: entity.categoryId,
      unitId: entity.unitId,
      quantity: entity.quantity,
      unitPriceCents: entity.unitPrice.cents,
      discountCents: entity.discount.cents,
      additionalCostCents: entity.additionalCost.cents,
    );
  }
}
