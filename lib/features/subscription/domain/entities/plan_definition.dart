import 'package:get/get.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';

/// Um plano do catálogo: preço, limites e módulos liberados.
class PlanDefinition {
  final String id;
  final String _name;
  final String _tagline;

  /// Nome e frase do plano no idioma atual.
  String get name => _name.tr;
  String get tagline => _tagline.tr;

  /// Ordem de "tamanho" do plano (0 = Grátis). Usada para saber se uma
  /// troca é upgrade ou downgrade.
  final int rank;
  final Money monthlyPrice;
  final Money yearlyPrice;

  /// Limite por recurso. Recurso ausente ou `null` = ilimitado.
  final Map<ResourceKey, int?> limits;
  final Set<FeatureKey> features;

  /// Destaque visual ("Mais escolhido").
  final bool recommended;

  const PlanDefinition({
    required this.id,
    required String name,
    required String tagline,
    required this.rank,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.limits,
    required this.features,
    this.recommended = false,
  }) : _name = name,
       _tagline = tagline;

  bool get isFree => monthlyPrice.isZero && yearlyPrice.isZero;

  int? limitOf(ResourceKey resource) => limits[resource];

  bool has(FeatureKey feature) => features.contains(feature);

  Money priceFor(BillingPeriod period) => switch (period) {
        BillingPeriod.monthly => monthlyPrice,
        BillingPeriod.yearly => yearlyPrice,
      };

  /// Quanto o anual economiza em relação a 12 mensalidades.
  Money get yearlySavings => monthlyPrice * 12 - yearlyPrice;
}
