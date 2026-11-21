import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';

/// O que o usuário pode usar agora: o plano em vigor e, se houver, a
/// assinatura que o liberou.
class Entitlement {
  final PlanDefinition plan;
  final SubscriptionEntity? subscription;

  /// A assinatura existia mas venceu (o plano em vigor voltou a ser o Grátis).
  final bool expired;

  const Entitlement({required this.plan, this.subscription, this.expired = false});

  static const free = Entitlement(plan: PlanCatalog.free);

  /// Monta o entitlement a partir da assinatura salva (ou da falta dela).
  factory Entitlement.resolve(SubscriptionEntity? subscription, {DateTime? now}) {
    if (subscription == null) return free;
    final active = subscription.isActiveAt(now ?? DateTime.now());
    if (!active) return Entitlement(plan: PlanCatalog.free, subscription: subscription, expired: true);
    return Entitlement(plan: PlanCatalog.byId(subscription.planId), subscription: subscription);
  }

  int? limitOf(ResourceKey resource) => plan.limitOf(resource);

  bool has(FeatureKey feature) => plan.has(feature);
}
