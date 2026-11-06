import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/domain/entities/discount_rule.dart';

class TransactionItemEntity {
  final String id;
  final String transactionId;
  final String? productId;
  final String nameSnapshot;
  final String? categoryId;
  final String? productTypeId;
  final String unitId;
  final double quantity;
  final Money unitPrice;
  final Money discount;
  final Money additionalCost;

  /// Promoção aplicada ao item, se houver. Quando presente, [discount] é
  /// o resultado de `discountRule.calculate(...)` no momento em que o item
  /// foi salvo (ver [withRecalculatedDiscount]) — fica gravado como
  /// snapshot para relatórios antigos não mudarem.
  final DiscountRule? discountRule;

  const TransactionItemEntity({
    required this.id,
    required this.transactionId,
    this.productId,
    required this.nameSnapshot,
    this.categoryId,
    this.productTypeId,
    required this.unitId,
    required this.quantity,
    required this.unitPrice,
    this.discount = Money.zero,
    this.additionalCost = Money.zero,
    this.discountRule,
  });

  Money get subtotal => unitPrice * quantity;
  Money get total => subtotal - discount + additionalCost;

  /// Recalcula [discount] a partir de [discountRule] para a quantidade e o
  /// preço atuais. Sem regra, devolve o item como está.
  TransactionItemEntity withRecalculatedDiscount() {
    final rule = discountRule;
    if (rule == null) return this;
    return copyWith(discount: rule.calculate(itemQuantity: quantity, unitPrice: unitPrice));
  }

  TransactionItemEntity copyWith({
    String? id,
    String? transactionId,
    String? productId,
    String? nameSnapshot,
    String? categoryId,
    String? productTypeId,
    String? unitId,
    double? quantity,
    Money? unitPrice,
    Money? discount,
    Money? additionalCost,
    DiscountRule? discountRule,
    bool clearDiscountRule = false,
  }) {
    return TransactionItemEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      categoryId: categoryId ?? this.categoryId,
      productTypeId: productTypeId ?? this.productTypeId,
      unitId: unitId ?? this.unitId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      additionalCost: additionalCost ?? this.additionalCost,
      discountRule: clearDiscountRule ? null : (discountRule ?? this.discountRule),
    );
  }
}
