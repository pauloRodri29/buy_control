import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/custom_plan_pricing.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';
import 'package:buy_control/features/subscription/domain/entities/custom_plan_config.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';
import 'package:buy_control/features/subscription/domain/repositories/billing_gateway.dart';
import 'package:buy_control/features/subscription/domain/repositories/coupon_repository.dart';
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
///
/// - [customConfig]: assina o Personalizado com essa configuração (o
///   [plan] é ignorado e montado a partir dela).
/// - [coupon]: desconto já validado ([ValidateCoupon]); é marcado como
///   usado depois da compra aprovada.
class PurchasePlan {
  final SubscriptionRepository repository;
  final BillingGateway billing;
  final CouponRepository? coupons;

  const PurchasePlan({required this.repository, required this.billing, this.coupons});

  Future<Result<SubscriptionEntity>> call({
    required String userId,
    required PlanDefinition plan,
    required BillingPeriod period,
    CustomPlanConfig? customConfig,
    Coupon? coupon,
    DateTime? now,
  }) async {
    if (customConfig != null) {
      if (CustomPlanPricing.monthlyPrice(customConfig) > CustomPlanPricing.maxMonthly) {
        return Failure(ValidationFailure('subscription.customOverCap'.trParams({
          'max': CustomPlanPricing.maxMonthly.formatted,
        })));
      }
      plan = CustomPlanPricing.buildPlan(customConfig);
    }
    if (plan.isFree) {
      return Failure(ValidationFailure('subscription.freePlanDoesntNeedSubscription'.tr));
    }
    if (coupon != null && !coupon.appliesTo(plan.id)) {
      return Failure(ValidationFailure('subscription.couponNotForPlan'.trParams({'name': plan.name})));
    }

    final original = plan.priceFor(period);
    final price = coupon?.apply(original) ?? original;
    final receipt = await billing.purchase(PurchaseRequest(
      plan: plan,
      period: period,
      price: price,
      originalPrice: coupon == null ? null : original,
      couponCode: coupon?.code,
    ));
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
      customConfig: customConfig,
      couponCode: coupon?.code,
    );
    final saved = await repository.save(subscription);
    if (saved case Failure(:final failure)) return Failure(failure);
    if (coupon != null) await coupons?.markRedeemed(userId, coupon.code);
    return Success(subscription);
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
