import 'package:buy_control/core/money/money.dart';

enum CouponKind { percent, fixed }

/// Cupom de desconto. Com a loja, cada cupom aponta para uma oferta
/// cadastrada nela ou para um degrau mais baixo da escada (ver
/// docs/MONETIZATION.md); no modo simulado, o desconto é aplicado direto.
class Coupon {
  final String code;
  final CouponKind kind;

  /// Percentual (0–100) quando [kind] é `percent`.
  final int percent;

  /// Valor abatido quando [kind] é `fixed`.
  final Money amount;

  /// Planos em que vale (`null` = todos os pagos). Use os ids do catálogo
  /// e `custom` para o Personalizado.
  final Set<String>? planIds;
  final DateTime? validUntil;

  /// Só vale para quem nunca assinou.
  final bool firstSubscriptionOnly;

  const Coupon({
    required this.code,
    required this.kind,
    this.percent = 0,
    this.amount = Money.zero,
    this.planIds,
    this.validUntil,
    this.firstSubscriptionOnly = false,
  });

  bool appliesTo(String planId) => planIds == null || planIds!.contains(planId);

  bool isExpiredAt(DateTime now) => validUntil != null && !now.isBefore(validUntil!);

  /// Quanto o cupom abate de [price] (nunca mais que o próprio preço).
  Money discountOn(Money price) {
    final raw = switch (kind) {
      CouponKind.percent => Money((price.cents * percent / 100).round()),
      CouponKind.fixed => amount,
    };
    return raw > price ? price : raw;
  }

  Money apply(Money price) => price - discountOn(price);
}
