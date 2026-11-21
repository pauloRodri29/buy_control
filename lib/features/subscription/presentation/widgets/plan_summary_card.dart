import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/pages/my_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Atalho para "Meu plano" (no Perfil): ícone do plano, nome e situação
/// da assinatura. Atualiza sozinho quando o plano muda.
class PlanSummaryCard extends StatelessWidget {
  const PlanSummaryCard({super.key});

  static String _status(Entitlement entitlement) {
    final subscription = entitlement.subscription;
    if (subscription == null) return 'subscription.profilePlanFreeHint'.tr;
    final date = DateTimeFormatter.ddMMyyyy(subscription.expiresAt);
    if (entitlement.expired) return 'subscription.subscriptionExpiredDate'.trParams({'date': date});
    return subscription.autoRenew
        ? 'subscription.renewsDate'.trParams({'date': date})
        : 'subscription.activeUntilRenewalOffDate'.trParams({'date': date});
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (controller) {
        final entitlement = controller.entitlement;
        final plan = entitlement.plan;

        return AppCard(
          onTap: () => Get.to(() => const MyPlanPage()),
          child: Row(
            children: [
              // Quadrado (não círculo) para não se confundir com o avatar:
              // selo vazado no Grátis, preenchido em âmbar nos pagos.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderLg,
                  color: plan.isFree ? context.colors.surfaceContainerHighest : null,
                  gradient: plan.isFree
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppBrand.terminal, AppBrand.teal],
                        ),
                ),
                child: Icon(
                  Symbols.workspace_premium,
                  color: plan.isFree ? context.colors.onSurfaceVariant : AppBrand.amber,
                  fill: plan.isFree ? 0 : 1,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('common.myPlan'.tr, style: context.text.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      'common.planName'.trParams({'name': plan.name}),
                      style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(_status(entitlement), style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right, size: 18, color: context.colors.onSurfaceVariant),
            ],
          ),
        );
      },
    );
  }
}
