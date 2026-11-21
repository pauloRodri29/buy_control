import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';

/// Serialização da assinatura no Hive (um registro por usuário).
class SubscriptionModel {
  SubscriptionModel._();

  static Map<String, dynamic> toMap(SubscriptionEntity s) => {
        'userId': s.userId,
        'planId': s.planId,
        'period': s.period.name,
        'pricePaidCents': s.pricePaid.cents,
        'startedAt': s.startedAt.toIso8601String(),
        'expiresAt': s.expiresAt.toIso8601String(),
        'autoRenew': s.autoRenew,
        'source': s.source.name,
      };

  static SubscriptionEntity fromMap(Map<String, dynamic> map) => SubscriptionEntity(
        userId: map['userId'] as String,
        planId: map['planId'] as String,
        period: BillingPeriod.values.asNameMap()[map['period']] ?? BillingPeriod.monthly,
        pricePaid: Money((map['pricePaidCents'] as num?)?.toInt() ?? 0),
        startedAt: DateTime.parse(map['startedAt'] as String),
        expiresAt: DateTime.parse(map['expiresAt'] as String),
        autoRenew: map['autoRenew'] as bool? ?? true,
        source: SubscriptionSource.values.asNameMap()[map['source']] ?? SubscriptionSource.simulated,
      );
}
