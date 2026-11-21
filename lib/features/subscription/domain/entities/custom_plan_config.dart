import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';

/// O que o usuário escolheu no plano Personalizado: os módulos extras e,
/// por recurso, quantos pacotes a mais além do limite do Grátis.
class CustomPlanConfig {
  /// Valor de [packs] que significa "ilimitado".
  static const unlimited = -1;

  final Set<FeatureKey> modules;
  final Map<ResourceKey, int> packs;

  const CustomPlanConfig({this.modules = const {}, this.packs = const {}});

  static const empty = CustomPlanConfig();

  int packsOf(ResourceKey resource) => packs[resource] ?? 0;

  bool isUnlimited(ResourceKey resource) => packs[resource] == unlimited;

  bool get isEmpty => modules.isEmpty && packs.values.every((p) => p == 0);

  CustomPlanConfig withModule(FeatureKey feature, bool enabled) => CustomPlanConfig(
        modules: enabled ? {...modules, feature} : ({...modules}..remove(feature)),
        packs: packs,
      );

  CustomPlanConfig withPacks(ResourceKey resource, int value) =>
      CustomPlanConfig(modules: modules, packs: {...packs, resource: value});

  Map<String, dynamic> toMap() => {
        'modules': [for (final m in modules) m.name],
        'packs': {for (final e in packs.entries) e.key.name: e.value},
      };

  factory CustomPlanConfig.fromMap(Map<String, dynamic> map) {
    final features = FeatureKey.values.asNameMap();
    final resources = ResourceKey.values.asNameMap();
    return CustomPlanConfig(
      modules: {
        for (final name in (map['modules'] as List? ?? const []))
          if (features[name] case final feature?) feature,
      },
      packs: {
        for (final e in Map<String, dynamic>.from(map['packs'] as Map? ?? const {}).entries)
          if (resources[e.key] case final resource?) resource: (e.value as num).toInt(),
      },
    );
  }
}
