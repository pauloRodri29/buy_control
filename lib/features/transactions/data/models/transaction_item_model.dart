class TransactionItemModel {
  final String id;
  final String transactionId;
  final String? productId;
  final String nameSnapshot;
  final String? categoryId;
  final String? productTypeId;
  final String unitId;
  final double quantity;
  final int unitPriceCents;
  final int discountCents;
  final int additionalCostCents;

  /// Regra de promoção serializada (`DiscountRule.toMap`), ou `null`.
  final Map<String, dynamic>? discountRule;

  const TransactionItemModel({
    required this.id,
    required this.transactionId,
    this.productId,
    required this.nameSnapshot,
    this.categoryId,
    this.productTypeId,
    required this.unitId,
    required this.quantity,
    required this.unitPriceCents,
    required this.discountCents,
    required this.additionalCostCents,
    this.discountRule,
  });

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as String,
      transactionId: map['transactionId'] as String,
      productId: map['productId'] as String?,
      nameSnapshot: map['nameSnapshot'] as String,
      categoryId: map['categoryId'] as String?,
      productTypeId: map['productTypeId'] as String?,
      unitId: map['unitId'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPriceCents: (map['unitPriceCents'] as num).toInt(),
      discountCents: (map['discountCents'] as num?)?.toInt() ?? 0,
      additionalCostCents: (map['additionalCostCents'] as num?)?.toInt() ?? 0,
      discountRule: map['discountRule'] is Map ? Map<String, dynamic>.from(map['discountRule'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productId': productId,
      'nameSnapshot': nameSnapshot,
      'categoryId': categoryId,
      'productTypeId': productTypeId,
      'unitId': unitId,
      'quantity': quantity,
      'unitPriceCents': unitPriceCents,
      'discountCents': discountCents,
      'additionalCostCents': additionalCostCents,
      'discountRule': discountRule,
    };
  }
}
