import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';

/// Catálogo de planos embarcado no app. Quando houver backend, vira o
/// fallback de um catálogo remoto (ver docs/MONETIZATION.md).
class PlanCatalog {
  PlanCatalog._();

  static const freeId = 'free';
  static const essentialId = 'essential';
  static const proId = 'pro';
  static const premiumId = 'premium';

  static const _base = {
    FeatureKey.planning,
    FeatureKey.backupManual,
    FeatureKey.barcodeScanner,
    FeatureKey.carryOver,
  };

  static const _essential = {
    ..._base,
    FeatureKey.dashboardCharts,
    FeatureKey.discountRules,
    FeatureKey.reportsAdvanced,
    FeatureKey.exportPdf,
  };

  static const _pro = {
    ..._essential,
    FeatureKey.reportsCompare,
    FeatureKey.scaleLabel,
    FeatureKey.priceHistory,
    FeatureKey.budgets,
    FeatureKey.backupAuto,
  };

  static const _premium = {..._pro, FeatureKey.cloudSync};

  static const free = PlanDefinition(
    id: freeId,
    name: 'subscription.free',
    tagline: 'subscription.essentialsControlMonth',
    rank: 0,
    monthlyPrice: Money.zero,
    yearlyPrice: Money.zero,
    limits: {
      ResourceKey.boxes: 3,
      ResourceKey.products: 60,
      ResourceKey.categories: 5,
      ResourceKey.productTypes: 5,
      ResourceKey.units: 5,
      ResourceKey.planBoards: 1,
      ResourceKey.planItemsPerBoard: 15,
    },
    features: _base,
  );

  static const essential = PlanDefinition(
    id: essentialId,
    name: 'subscription.essential',
    tagline: 'subscription.organizedHome',
    rank: 1,
    monthlyPrice: Money(690),
    yearlyPrice: Money(5990),
    limits: {
      ResourceKey.boxes: 10,
      ResourceKey.products: 300,
      ResourceKey.categories: 20,
      ResourceKey.productTypes: 20,
      ResourceKey.units: 20,
      ResourceKey.planBoards: 3,
      ResourceKey.planItemsPerBoard: 50,
    },
    features: _essential,
  );

  static const pro = PlanDefinition(
    id: proId,
    name: 'Pro',
    tagline: 'subscription.fullControlReports',
    rank: 2,
    monthlyPrice: Money(1290),
    yearlyPrice: Money(10990),
    limits: {
      ResourceKey.boxes: 30,
      ResourceKey.products: 1500,
      ResourceKey.categories: null,
      ResourceKey.productTypes: null,
      ResourceKey.units: null,
      ResourceKey.planBoards: 10,
      ResourceKey.planItemsPerBoard: 200,
    },
    features: _pro,
    recommended: true,
  );

  static const premium = PlanDefinition(
    id: premiumId,
    name: 'Premium',
    tagline: 'subscription.noLimitsAllDevices',
    rank: 3,
    monthlyPrice: Money(1990),
    yearlyPrice: Money(16990),
    limits: {},
    features: _premium,
  );

  static const all = [free, essential, pro, premium];

  static PlanDefinition byId(String? id) => all.firstWhere((p) => p.id == id, orElse: () => free);
}
