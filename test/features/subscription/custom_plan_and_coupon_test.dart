import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/custom_plan_pricing.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';
import 'package:buy_control/features/subscription/domain/entities/custom_plan_config.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';
import 'package:buy_control/features/subscription/domain/repositories/billing_gateway.dart';
import 'package:buy_control/features/subscription/domain/repositories/coupon_repository.dart';
import 'package:buy_control/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:buy_control/features/subscription/domain/usecases/coupon_usecases.dart';
import 'package:buy_control/features/subscription/domain/usecases/subscription_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements SubscriptionRepository {
  final store = <String, SubscriptionEntity>{};

  @override
  Future<Result<SubscriptionEntity?>> get(String userId) async => Success(store[userId]);

  @override
  Future<Result<void>> save(SubscriptionEntity s) async {
    store[s.userId] = s;
    return const Success(null);
  }

  @override
  Future<Result<void>> clear(String userId) async {
    store.remove(userId);
    return const Success(null);
  }
}

class _Coupons implements CouponRepository {
  final List<Coupon> all;
  final used = <String>{};
  _Coupons(this.all);

  @override
  Future<Result<Coupon?>> find(String code) async => Success(all.where((c) => c.code == code).firstOrNull);

  @override
  Future<Result<bool>> wasRedeemed(String userId, String code) async => Success(used.contains('$userId:$code'));

  @override
  Future<Result<void>> markRedeemed(String userId, String code) async {
    used.add('$userId:$code');
    return const Success(null);
  }

  @override
  Future<Result<void>> clearRedeemed(String userId) async {
    used.removeWhere((k) => k.startsWith('$userId:'));
    return const Success(null);
  }
}

/// Aprova tudo e guarda o último pedido, para conferir o valor cobrado.
class _Billing implements BillingGateway {
  PurchaseRequest? last;

  @override
  bool get isSimulated => true;

  @override
  Future<Result<PurchaseReceipt>> purchase(PurchaseRequest request) async {
    last = request;
    return Success(PurchaseReceipt(
      transactionId: 't',
      purchasedAt: DateTime(2026, 5, 1),
      source: SubscriptionSource.simulated,
    ));
  }
}

void main() {
  group('Preço do Personalizado', () {
    test('sem nada escolhido custa o mínimo da escada', () {
      expect(CustomPlanPricing.monthlyPrice(CustomPlanConfig.empty), CustomPlanPricing.minMonthly);
    });

    test('soma taxa base, módulos e pacotes, sempre em reais inteiros', () {
      final config = CustomPlanConfig.empty
          .withModule(FeatureKey.reportsAdvanced, true) // R$ 2
          .withModule(FeatureKey.exportPdf, true) // R$ 1
          .withPacks(ResourceKey.boxes, 2) // 2 × R$ 1
          .withPacks(ResourceKey.products, CustomPlanConfig.unlimited); // R$ 5
      final monthly = CustomPlanPricing.monthlyPrice(config);
      expect(monthly, const Money(300 + 200 + 100 + 200 + 500));
      expect(monthly.cents % 100, 0, reason: 'precisa existir na escada da loja');
      expect(CustomPlanPricing.priceFor(config, BillingPeriod.yearly), monthly * 10);
    });

    test('plano montado: limites do Grátis + pacotes, módulos do Grátis + escolhidos', () {
      final config = CustomPlanConfig.empty
          .withModule(FeatureKey.reportsCompare, true)
          .withPacks(ResourceKey.boxes, 3)
          .withPacks(ResourceKey.categories, CustomPlanConfig.unlimited);
      final plan = CustomPlanPricing.buildPlan(config);
      expect(plan.limitOf(ResourceKey.boxes), 3 + 3 * 5);
      expect(plan.limitOf(ResourceKey.categories), isNull);
      expect(plan.limitOf(ResourceKey.products), PlanCatalog.free.limitOf(ResourceKey.products));
      expect(plan.has(FeatureKey.reportsCompare), isTrue);
      expect(plan.has(FeatureKey.planning), isTrue);
      expect(plan.has(FeatureKey.exportPdf), isFalse);
    });

    test('sugere o plano pronto quando ele cobre tudo por menos', () {
      final everythingEssential = CustomPlanConfig(
        modules: {
          FeatureKey.dashboardCharts,
          FeatureKey.discountRules,
          FeatureKey.reportsAdvanced,
          FeatureKey.exportPdf,
        },
        packs: {ResourceKey.boxes: 1, ResourceKey.products: 2},
      );
      final price = CustomPlanPricing.priceFor(everythingEssential, BillingPeriod.monthly);
      final suggestion = CustomPlanPricing.cheaperStandardPlan(everythingEssential, BillingPeriod.monthly, price);
      expect(suggestion?.id, PlanCatalog.essentialId);

      final small = CustomPlanConfig.empty.withModule(FeatureKey.exportPdf, true);
      final smallPrice = CustomPlanPricing.priceFor(small, BillingPeriod.monthly);
      expect(CustomPlanPricing.cheaperStandardPlan(small, BillingPeriod.monthly, smallPrice), isNull);
    });

    test('configuração sobrevive a salvar e ler (toMap/fromMap)', () {
      final config = CustomPlanConfig.empty
          .withModule(FeatureKey.scaleLabel, true)
          .withPacks(ResourceKey.planBoards, CustomPlanConfig.unlimited);
      final back = CustomPlanConfig.fromMap(config.toMap());
      expect(back.modules, {FeatureKey.scaleLabel});
      expect(back.isUnlimited(ResourceKey.planBoards), isTrue);
    });
  });

  group('Cupons', () {
    test('percentual e valor fixo, nunca abaixo de zero', () {
      const pct = Coupon(code: 'A', kind: CouponKind.percent, percent: 20);
      const fixed = Coupon(code: 'B', kind: CouponKind.fixed, amount: Money(500));
      expect(pct.apply(const Money(1290)), const Money(1032));
      expect(fixed.apply(const Money(1290)), const Money(790));
      expect(fixed.apply(const Money(300)), Money.zero);
    });

    test('validação: inexistente, vencido, já usado e só primeira assinatura', () async {
      final repo = _Repo();
      final coupons = _Coupons([
        const Coupon(code: 'OK10', kind: CouponKind.percent, percent: 10),
        Coupon(code: 'OLD', kind: CouponKind.percent, percent: 10, validUntil: DateTime(2020)),
        const Coupon(code: 'NEW', kind: CouponKind.percent, percent: 50, firstSubscriptionOnly: true),
      ]);
      final validate = ValidateCoupon(coupons: coupons, subscriptions: repo);

      expect((await validate('ok10', userId: 'u')).dataOrNull?.code, 'OK10');
      expect((await validate('NADA', userId: 'u')).failureOrNull, isA<ValidationFailure>());
      expect((await validate('OLD', userId: 'u')).failureOrNull, isA<ValidationFailure>());

      await coupons.markRedeemed('u', 'OK10');
      expect((await validate('OK10', userId: 'u')).failureOrNull, isA<ValidationFailure>());

      expect((await validate('NEW', userId: 'u')).isSuccess, isTrue);
      await repo.save(SubscriptionEntity(
        userId: 'u',
        planId: PlanCatalog.proId,
        period: BillingPeriod.monthly,
        pricePaid: PlanCatalog.pro.monthlyPrice,
        startedAt: DateTime(2026),
        expiresAt: DateTime(2026, 2),
      ));
      expect((await validate('NEW', userId: 'u')).failureOrNull, isA<ValidationFailure>());
    });
  });

  group('Compra do Personalizado com cupom', () {
    test('cobra a soma com desconto, grava a configuração e marca o cupom como usado', () async {
      final repo = _Repo();
      final coupons = _Coupons(const []);
      final billing = _Billing();
      final config = CustomPlanConfig.empty
          .withModule(FeatureKey.reportsAdvanced, true)
          .withPacks(ResourceKey.boxes, 2); // 3 + 2 + 2 = R$ 7
      const coupon = Coupon(code: 'MONTE30', kind: CouponKind.percent, percent: 30, planIds: {'custom'});

      final result = await PurchasePlan(repository: repo, billing: billing, coupons: coupons)(
        userId: 'u',
        plan: PlanCatalog.free,
        period: BillingPeriod.monthly,
        customConfig: config,
        coupon: coupon,
      );

      expect(result.isSuccess, isTrue);
      expect(billing.last!.originalPrice, const Money(700));
      expect(billing.last!.price, const Money(490));
      expect(repo.store['u']!.couponCode, 'MONTE30');
      expect(coupons.used, contains('u:MONTE30'));

      final entitlement = Entitlement.resolve(repo.store['u'], now: DateTime(2026, 5, 10));
      expect(entitlement.plan.id, CustomPlanPricing.planId);
      expect(entitlement.limitOf(ResourceKey.boxes), 13);
      expect(entitlement.has(FeatureKey.reportsAdvanced), isTrue);
    });

    test('cupom de outro plano é recusado antes de cobrar', () async {
      final billing = _Billing();
      const onlyCustom = Coupon(code: 'X', kind: CouponKind.percent, percent: 30, planIds: {'custom'});
      final result = await PurchasePlan(repository: _Repo(), billing: billing)(
        userId: 'u',
        plan: PlanCatalog.pro,
        period: BillingPeriod.monthly,
        coupon: onlyCustom,
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(billing.last, isNull);
    });

    test('acima do teto não deixa assinar', () async {
      var config = CustomPlanConfig.empty;
      for (final f in CustomPlanPricing.modulePrices.keys) {
        config = config.withModule(f, true);
      }
      for (final p in CustomPlanPricing.packs) {
        config = config.withPacks(p.resource, p.maxPacks);
      }
      expect(CustomPlanPricing.monthlyPrice(config) > CustomPlanPricing.maxMonthly, isTrue);
      final result = await PurchasePlan(repository: _Repo(), billing: _Billing())(
        userId: 'u',
        plan: PlanCatalog.free,
        period: BillingPeriod.monthly,
        customConfig: config,
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
