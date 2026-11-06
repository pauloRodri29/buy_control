import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';

/// Tipos de promoção suportados no item de um lançamento.
enum DiscountType {
  /// Valor fixo em R$ abatido do subtotal do item.
  fixed,

  /// Percentual sobre o subtotal do item.
  percent,

  /// "Leve N por R$ X": cada grupo completo de N unidades sai por X; o que
  /// sobrar fora de um grupo é cobrado pelo preço unitário normal.
  bundlePrice,

  /// "Leve N, pague M": a cada grupo completo de N unidades, paga-se só M.
  buyXPayY,

  /// "A partir de N unidades, R$ X cada": atingida a quantidade mínima,
  /// todas as unidades saem pelo preço especial.
  wholesale,
}

extension DiscountTypeLabel on DiscountType {
  String get label {
    switch (this) {
      case DiscountType.fixed:
        return 'Valor fixo (R\$)';
      case DiscountType.percent:
        return 'Percentual (%)';
      case DiscountType.bundlePrice:
        return 'Leve N por R\$ X';
      case DiscountType.buyXPayY:
        return 'Leve N, pague M';
      case DiscountType.wholesale:
        return 'Preço a partir de N un.';
    }
  }
}

/// Regra de desconto de um item. O valor final do desconto nunca é
/// digitado à mão: é sempre derivado por [calculate] a partir da
/// quantidade e do preço unitário do item, e o resultado é gravado em
/// `TransactionItemEntity.discount` como snapshot do momento do lançamento.
///
/// Campos usados por tipo:
/// - [DiscountType.fixed]: [amount]
/// - [DiscountType.percent]: [percent]
/// - [DiscountType.bundlePrice]: [quantity] (N) + [amount] (X)
/// - [DiscountType.buyXPayY]: [quantity] (N) + [payQuantity] (M)
/// - [DiscountType.wholesale]: [quantity] (mínimo) + [amount] (preço especial)
class DiscountRule {
  final DiscountType type;
  final Money amount;
  final double percent;
  final int quantity;
  final int payQuantity;

  const DiscountRule({
    required this.type,
    this.amount = Money.zero,
    this.percent = 0,
    this.quantity = 0,
    this.payQuantity = 0,
  });

  const DiscountRule.fixed(Money value) : this(type: DiscountType.fixed, amount: value);
  const DiscountRule.percent(double value) : this(type: DiscountType.percent, percent: value);
  const DiscountRule.bundlePrice({required int quantity, required Money price})
      : this(type: DiscountType.bundlePrice, quantity: quantity, amount: price);
  const DiscountRule.buyXPayY({required int take, required int pay})
      : this(type: DiscountType.buyXPayY, quantity: take, payQuantity: pay);
  const DiscountRule.wholesale({required int minQuantity, required Money unitPrice})
      : this(type: DiscountType.wholesale, quantity: minQuantity, amount: unitPrice);

  /// Desconto resultante para [itemQuantity] unidades a [unitPrice] cada.
  /// Nunca é negativo nem maior que o subtotal do item; parâmetros
  /// inválidos (ex.: N = 0) simplesmente resultam em desconto zero.
  Money calculate({required double itemQuantity, required Money unitPrice}) {
    final subtotal = unitPrice * itemQuantity;
    if (itemQuantity <= 0 || subtotal.cents <= 0) return Money.zero;

    final Money raw;
    switch (type) {
      case DiscountType.fixed:
        raw = amount;
      case DiscountType.percent:
        raw = percent <= 0 ? Money.zero : subtotal * (percent / 100);
      case DiscountType.bundlePrice:
        if (quantity <= 0) return Money.zero;
        final groups = itemQuantity ~/ quantity;
        final remainder = itemQuantity - groups * quantity;
        final paid = amount * groups + unitPrice * remainder;
        raw = subtotal - paid;
      case DiscountType.buyXPayY:
        if (quantity <= 0 || payQuantity < 0 || payQuantity >= quantity) return Money.zero;
        final groups = itemQuantity ~/ quantity;
        raw = unitPrice * (groups * (quantity - payQuantity));
      case DiscountType.wholesale:
        if (quantity <= 0 || itemQuantity < quantity) return Money.zero;
        raw = (unitPrice - amount) * itemQuantity;
    }

    if (raw.isNegative) return Money.zero;
    return raw > subtotal ? subtotal : raw;
  }

  /// Descrição curta para listas/resumos, ex.: "Leve 4 por R$ 10,00".
  String get description {
    switch (type) {
      case DiscountType.fixed:
        return '${amount.formatted} de desconto';
      case DiscountType.percent:
        final value = QuantityFormatter.format(percent);
        return '$value% de desconto';
      case DiscountType.bundlePrice:
        return 'Leve $quantity por ${amount.formatted}';
      case DiscountType.buyXPayY:
        return 'Leve $quantity, pague $payQuantity';
      case DiscountType.wholesale:
        return 'A partir de $quantity un., ${amount.formatted} cada';
    }
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'amountCents': amount.cents,
        'percent': percent,
        'quantity': quantity,
        'payQuantity': payQuantity,
      };

  static DiscountRule? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final type = DiscountType.values.where((t) => t.name == map['type']).firstOrNull;
    if (type == null) return null;
    return DiscountRule(
      type: type,
      amount: Money((map['amountCents'] as num?)?.toInt() ?? 0),
      percent: (map['percent'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      payQuantity: (map['payQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscountRule &&
      other.type == type &&
      other.amount == amount &&
      other.percent == percent &&
      other.quantity == quantity &&
      other.payQuantity == payQuantity;

  @override
  int get hashCode => Object.hash(type, amount, percent, quantity, payQuantity);
}
