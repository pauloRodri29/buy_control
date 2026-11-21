import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';

/// De onde veio a assinatura. `simulated` = pagamento de teste, sem
/// cobrança real (enquanto não há loja/backend).
enum SubscriptionSource { simulated, store, promotional }

/// Assinatura paga do usuário. Sem assinatura (ou vencida) = plano Grátis.
class SubscriptionEntity {
  final String userId;
  final String planId;
  final BillingPeriod period;
  final Money pricePaid;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool autoRenew;
  final SubscriptionSource source;

  const SubscriptionEntity({
    required this.userId,
    required this.planId,
    required this.period,
    required this.pricePaid,
    required this.startedAt,
    required this.expiresAt,
    this.autoRenew = true,
    this.source = SubscriptionSource.simulated,
  });

  bool isActiveAt(DateTime now) => now.isBefore(expiresAt);

  /// Próximo vencimento contando a partir de [from].
  static DateTime nextExpiry(DateTime from, BillingPeriod period) => switch (period) {
        BillingPeriod.monthly => DateTime(from.year, from.month + 1, from.day, from.hour, from.minute),
        BillingPeriod.yearly => DateTime(from.year + 1, from.month, from.day, from.hour, from.minute),
      };

  SubscriptionEntity copyWith({DateTime? expiresAt, bool? autoRenew}) {
    return SubscriptionEntity(
      userId: userId,
      planId: planId,
      period: period,
      pricePaid: pricePaid,
      startedAt: startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenew: autoRenew ?? this.autoRenew,
      source: source,
    );
  }
}
