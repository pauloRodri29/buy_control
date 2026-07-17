import 'package:buy_control/core/money/money.dart';

class TransactionItemEntity {
  final String id;
  final String transactionId;
  final String? productId;
  final String nameSnapshot;
  final String? categoryId;
  final String unitId;
  final double quantity;
  final Money unitPrice;
  final Money discount;
  final Money additionalCost;

  const TransactionItemEntity({
    required this.id,
    required this.transactionId,
    this.productId,
    required this.nameSnapshot,
    this.categoryId,
    required this.unitId,
    required this.quantity,
    required this.unitPrice,
    this.discount = Money.zero,
    this.additionalCost = Money.zero,
  });

  Money get subtotal => unitPrice * quantity;
  Money get total => subtotal - discount + additionalCost;

  TransactionItemEntity copyWith({
    String? productId,
    String? nameSnapshot,
    String? categoryId,
    String? unitId,
    double? quantity,
    Money? unitPrice,
    Money? discount,
    Money? additionalCost,
  }) {
    return TransactionItemEntity(
      id: id,
      transactionId: transactionId,
      productId: productId ?? this.productId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      additionalCost: additionalCost ?? this.additionalCost,
    );
  }
}
