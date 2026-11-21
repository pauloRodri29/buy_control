import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';
import 'package:buy_control/features/subscription/domain/repositories/billing_gateway.dart';
import 'package:buy_control/features/subscription/domain/repositories/subscription_repository.dart';

/// Plano em vigor do usuário. Assinatura vencida com renovação automática
/// é renovada aqui (no modo simulado não há cobrança; com a loja, quem
/// renova é a própria loja e isto só lê o estado).
class GetEntitlement {
  final SubscriptionRepository repository;
  final BillingGateway billing;

  const GetEntitlement({required this.repository, required this.billing});

  Future<Result<Entitlement>> call(String userId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final result = await repository.get(userId);
    if (result case Failure(:final failure)) return Failure(failure);

    var subscription = result.dataOrNull;
    if (subscription != null && billing.isSimulated && subscription.autoRenew && !subscription.isActiveAt(at)) {
      var expiresAt = subscription.expiresAt;
      while (!at.isBefore(expiresAt)) {
        expiresAt = SubscriptionEntity.nextExpiry(expiresAt, subscription.period);
      }
      subscription = subscription.copyWith(expiresAt: expiresAt);
      final saved = await repository.save(subscription);
      if (saved case Failure(:final failure)) return Failure(failure);
    }
    return Success(Entitlement.resolve(subscription, now: at));
  }
}

/// Assina (ou troca de) plano: cobra pelo [BillingGateway] e grava a
/// assinatura. O período começa na hora da compra.
class PurchasePlan {
  final SubscriptionRepository repository;
  final BillingGateway billing;

  const PurchasePlan({required this.repository, required this.billing});

  Future<Result<SubscriptionEntity>> call({
    required String userId,
    required PlanDefinition plan,
    required BillingPeriod period,
    DateTime? now,
  }) async {
    if (plan.isFree) {
      return Failure(ValidationFailure('subscription.freePlanDoesntNeedSubscription'.tr));
    }

    final price = plan.priceFor(period);
    final receipt = await billing.purchase(PurchaseRequest(plan: plan, period: period, price: price));
    if (receipt case Failure(:final failure)) return Failure(failure);

    final startedAt = now ?? receipt.dataOrNull!.purchasedAt;
    final subscription = SubscriptionEntity(
      userId: userId,
      planId: plan.id,
      period: period,
      pricePaid: price,
      startedAt: startedAt,
      expiresAt: SubscriptionEntity.nextExpiry(startedAt, period),
      source: receipt.dataOrNull!.source,
    );
    final saved = await repository.save(subscription);
    return saved.fold((_) => Success(subscription), (f) => Failure(f));
  }
}

/// Liga ou desliga a renovação automática. Desligada, o plano continua
/// até o vencimento e depois volta ao Grátis.
class SetAutoRenew {
  final SubscriptionRepository repository;

  const SetAutoRenew(this.repository);

  Future<Result<void>> call(SubscriptionEntity subscription, {required bool enabled}) {
    return repository.save(subscription.copyWith(autoRenew: enabled));
  }
}
