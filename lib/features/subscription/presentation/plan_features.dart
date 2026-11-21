import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/pages/plans_page.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_limit_prompt.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Módulos do plano na interface: [has] para decidir o que mostrar e
/// [ensure] para ações (toque num botão de um módulo não incluído abre o
/// aviso com o atalho para os planos).
class PlanFeatures {
  PlanFeatures._();

  /// Sem controller registrado (testes isolados), tudo fica liberado.
  static bool has(FeatureKey feature) =>
      !Get.isRegistered<SubscriptionController>() || Get.find<SubscriptionController>().entitlement.has(feature);

  /// `true` se pode usar; senão mostra o aviso do plano e devolve `false`.
  static bool ensure(FeatureKey feature) {
    if (has(feature)) return true;
    PlanLimitPrompt.show(message(feature), title: 'subscription.featureFromAnotherPlan'.tr);
    return false;
  }

  /// Plano mais barato que inclui [feature].
  static PlanDefinition? cheapestWith(FeatureKey feature) =>
      PlanCatalog.all.where((p) => p.has(feature)).firstOrNull;

  static String message(FeatureKey feature) {
    final plan = cheapestWith(feature);
    return plan == null
        ? 'subscription.notAvailableYetLabel'.trParams({'label': feature.label})
        : 'subscription.includedFromPlanUpLabelName'.trParams({'label': feature.label, 'name': plan.name});
  }
}

/// Lugar de um módulo não incluído no plano: cadeado, nome do módulo e a
/// partir de qual plano ele existe. Tocar abre a lista de planos.
class LockedFeatureCard extends StatelessWidget {
  final FeatureKey feature;

  /// Texto opcional sobre o que o módulo faz (no lugar do nome).
  final String? title;

  const LockedFeatureCard({super.key, required this.feature, this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plan = PlanFeatures.cheapestWith(feature);

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: () => Get.to(() => const PlansPage()),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
                child: Icon(Symbols.lock, size: 18, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? feature.label,
                      style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan == null ? 'common.comingSoon'.tr : 'subscription.availablePlanName'.trParams({'name': plan.name}),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Text('subscription.seePlans'.tr, style: context.text.labelMedium?.copyWith(color: colors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
