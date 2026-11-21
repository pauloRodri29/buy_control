import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/subscription/domain/entities/custom_plan_config.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';

/// Pacote de um recurso no Personalizado: cada pacote soma [size] ao
/// limite do Grátis por [price]/mês; "ilimitado" custa [unlimitedPrice].
class ResourcePack {
  final ResourceKey resource;
  final int size;
  final Money price;
  final int maxPacks;
  final Money unlimitedPrice;

  const ResourcePack({
    required this.resource,
    required this.size,
    required this.price,
    required this.maxPacks,
    required this.unlimitedPrice,
  });
}

/// Tabela de pesos do plano Personalizado (ver docs/MONETIZATION.md).
///
/// Todos os pesos são reais inteiros: a soma sempre cai num valor que
/// existe na "escada" de produtos da loja ([minMonthly]..[maxMonthly], de
/// R$ 1 em R$ 1), então o preço mostrado é exatamente o cobrado.
class CustomPlanPricing {
  CustomPlanPricing._();

  static const planId = 'custom';

  /// Fica entre o Grátis e o Essencial na comparação de "tamanho".
  static const rank = 1;

  static const baseFee = Money(300);
  static const minMonthly = Money(500);
  static const maxMonthly = Money(4000);

  /// Anual = 10 mensalidades (2 meses grátis), como nos planos prontos.
  static const yearlyMonths = 10;

  /// Módulos que podem ser acrescentados (os do Grátis já vêm incluídos).
  static const modulePrices = <FeatureKey, Money>{
    FeatureKey.dashboardCharts: Money(200),
    FeatureKey.discountRules: Money(100),
    FeatureKey.reportsAdvanced: Money(200),
    FeatureKey.reportsCompare: Money(100),
    FeatureKey.exportPdf: Money(100),
    FeatureKey.scaleLabel: Money(100),
  };

  static const packs = [
    ResourcePack(resource: ResourceKey.boxes, size: 5, price: Money(100), maxPacks: 6, unlimitedPrice: Money(400)),
    ResourcePack(resource: ResourceKey.products, size: 100, price: Money(100), maxPacks: 10, unlimitedPrice: Money(500)),
    ResourcePack(resource: ResourceKey.categories, size: 10, price: Money(100), maxPacks: 5, unlimitedPrice: Money(200)),
    ResourcePack(resource: ResourceKey.productTypes, size: 10, price: Money(100), maxPacks: 5, unlimitedPrice: Money(200)),
    ResourcePack(resource: ResourceKey.units, size: 10, price: Money(100), maxPacks: 5, unlimitedPrice: Money(200)),
    ResourcePack(resource: ResourceKey.planBoards, size: 2, price: Money(100), maxPacks: 5, unlimitedPrice: Money(300)),
    ResourcePack(resource: ResourceKey.planItemsPerBoard, size: 25, price: Money(100), maxPacks: 6, unlimitedPrice: Money(200)),
  ];

  static ResourcePack packFor(ResourceKey resource) => packs.firstWhere((p) => p.resource == resource);

  /// Limite resultante de [resource] na configuração (`null` = ilimitado).
  static int? limitFor(CustomPlanConfig config, ResourceKey resource) {
    if (config.isUnlimited(resource)) return null;
    final base = PlanCatalog.free.limitOf(resource) ?? 0;
    return base + config.packsOf(resource) * packFor(resource).size;
  }

  /// Preço de cada item escolhido, já mensal.
  static Money moduleCost(FeatureKey feature) => modulePrices[feature] ?? Money.zero;

  static Money resourceCost(CustomPlanConfig config, ResourceKey resource) {
    final pack = packFor(resource);
    if (config.isUnlimited(resource)) return pack.unlimitedPrice;
    return pack.price * config.packsOf(resource);
  }

  /// Soma mensal: taxa base + módulos + pacotes.
  static Money monthlyPrice(CustomPlanConfig config) {
    var total = baseFee;
    for (final feature in config.modules) {
      total += moduleCost(feature);
    }
    for (final pack in packs) {
      total += resourceCost(config, pack.resource);
    }
    return total < minMonthly ? minMonthly : total;
  }

  static Money priceFor(CustomPlanConfig config, BillingPeriod period) => switch (period) {
        BillingPeriod.monthly => monthlyPrice(config),
        BillingPeriod.yearly => monthlyPrice(config) * yearlyMonths,
      };

  /// O plano que a configuração libera, no mesmo formato dos planos prontos.
  static PlanDefinition buildPlan(CustomPlanConfig config) {
    final monthly = monthlyPrice(config);
    return PlanDefinition(
      id: planId,
      name: 'subscription.customPlan',
      tagline: 'subscription.customPlanTagline',
      rank: rank,
      monthlyPrice: monthly,
      yearlyPrice: monthly * yearlyMonths,
      limits: {for (final pack in packs) pack.resource: limitFor(config, pack.resource)},
      features: {...PlanCatalog.free.features, ...config.modules.where(modulePrices.containsKey)},
    );
  }

  /// Plano pronto que cobre tudo de [config] por no máximo [price] no
  /// mesmo período — se existir, o montador sugere trocar.
  static PlanDefinition? cheaperStandardPlan(CustomPlanConfig config, BillingPeriod period, Money price) {
    final custom = buildPlan(config);
    for (final plan in PlanCatalog.all.where((p) => !p.isFree)) {
      final coversFeatures = plan.features.containsAll(custom.features);
      final coversLimits = ResourceKey.values.every((r) {
        final need = custom.limitOf(r);
        final has = plan.limitOf(r);
        return has == null || (need != null && has >= need);
      });
      if (coversFeatures && coversLimits && plan.priceFor(period) <= price) return plan;
    }
    return null;
  }
}
