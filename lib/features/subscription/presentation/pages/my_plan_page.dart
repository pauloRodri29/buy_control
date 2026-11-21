import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/pages/plans_page.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_feature_row.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Meu plano": o plano atual com preço e situação, o uso de cada
/// recurso, o que está incluído e o controle da assinatura. A lista de
/// planos para assinar ou trocar fica em [PlansPage].
class MyPlanPage extends StatefulWidget {
  const MyPlanPage({super.key});

  @override
  State<MyPlanPage> createState() => _MyPlanPageState();
}

class _MyPlanPageState extends State<MyPlanPage> {
  final _controller = Get.find<SubscriptionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.load();
      await _controller.loadUsage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('common.myPlan'.tr)),
      body: GetBuilder<SubscriptionController>(
        builder: (controller) {
          final entitlement = controller.entitlement;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            children: [
              if (controller.isSimulated) ...[const _TestModeBanner(), const SizedBox(height: AppSpacing.md)],
              _CurrentPlanCard(entitlement: entitlement, onUpgrade: () => Get.to(() => const PlansPage())),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('subscription.usage'.tr),
              _UsageCard(plan: entitlement.plan, usage: controller.usage),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('subscription.includedPlan'.tr),
              _FeaturesCard(plan: entitlement.plan),
              if (entitlement.subscription != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle('common.subscription'.tr),
                _ManageCard(controller: controller),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title.toUpperCase(), style: context.text.labelMedium),
    );
  }
}

class _TestModeBanner extends StatelessWidget {
  const _TestModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: context.semantic.warningContainer, borderRadius: AppRadius.borderMd),
      child: Row(
        children: [
          Icon(Symbols.science, size: 18, color: context.semantic.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'subscription.testModePaymentsAreSimulated'.tr,
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de destaque do plano atual, no visual de terminal da marca.
class _CurrentPlanCard extends StatelessWidget {
  final Entitlement entitlement;
  final VoidCallback onUpgrade;

  const _CurrentPlanCard({required this.entitlement, required this.onUpgrade});

  String _status() {
    final subscription = entitlement.subscription;
    if (subscription == null) return 'subscription.noSubscriptionSubscribeUnlockMore'.tr;
    final date = DateTimeFormatter.ddMMyyyy(subscription.expiresAt);
    if (entitlement.expired) return 'subscription.subscriptionExpiredDate'.trParams({'date': date});
    return subscription.autoRenew ? 'subscription.renewsDate'.trParams({'date': date}) : 'subscription.activeUntilRenewalOffDate'.trParams({'date': date});
  }

  @override
  Widget build(BuildContext context) {
    final plan = entitlement.plan;
    final subscription = entitlement.expired ? null : entitlement.subscription;
    final isTop = plan.rank == PlanCatalog.all.last.rank;
    const onCard = Colors.white;
    final mono = TextStyle(fontFamily: AppBrand.monoFontFamily, color: AppBrand.terminalMuted, fontSize: 12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppBrand.terminal, Color(0xFF0E3B37), AppBrand.teal],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('subscription.currentPlan'.tr, style: mono),
              const Spacer(),
              Icon(
                Symbols.workspace_premium,
                color: AppBrand.amber,
                fill: plan.isFree ? 0 : 1,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            plan.name,
            style: context.text.headlineMedium?.copyWith(color: onCard, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(plan.tagline, style: context.text.bodyMedium?.copyWith(color: onCard.withValues(alpha: 0.8))),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                subscription == null ? 'R\$ 0' : subscription.pricePaid.formatted,
                style: context.text.headlineSmall?.copyWith(color: AppBrand.amber, fontWeight: FontWeight.w800),
              ),
              if (subscription != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(subscription.period.suffix, style: TextStyle(color: onCard.withValues(alpha: 0.8))),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(_status(), style: context.text.bodySmall?.copyWith(color: onCard.withValues(alpha: 0.75))),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: AppBrand.amber,
                foregroundColor: AppBrand.terminal,
                minimumSize: const Size(64, 48),
              ),
              icon: Icon(isTop ? Symbols.swap_horiz : Symbols.rocket_launch, size: 18),
              label: Text(isTop ? 'subscription.seePlans'.tr : 'subscription.upgrade'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final PlanDefinition plan;
  final Map<ResourceKey, int> usage;

  const _UsageCard({required this.plan, required this.usage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (final (i, resource) in ResourceKey.values.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              _UsageRow(resource: resource, used: usage[resource] ?? 0, limit: plan.limitOf(resource)),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final ResourceKey resource;
  final int used;
  final int? limit;

  const _UsageRow({required this.resource, required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final limit = this.limit;
    final over = limit != null && used > limit;
    final full = limit != null && used >= limit;
    final color = over ? colors.error : (full ? context.semantic.warning : colors.primary);
    final label = limit == null ? 'subscription.unlimitedUsed'.trParams({'used': '$used'}) : 'subscription.usedLimit'.trParams({'used': '$used', 'limit': '$limit'});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(resource.label, style: context.text.bodyMedium)),
            Text(label, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: over ? color : null)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: limit == null ? (used == 0 ? 0 : 1) : (limit == 0 ? 1 : (used / limit).clamp(0, 1).toDouble()),
            color: limit == null ? colors.primary.withValues(alpha: 0.35) : color,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
        if (over) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'subscription.lockedUntilYouUpgradeValue'.trParams({'value': '${used - limit}', 'vBValue': used - limit == 1 ? resource.singular : resource.plural}),
            style: context.text.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  final PlanDefinition plan;

  const _FeaturesCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            for (final feature in FeatureKey.values)
              PlanFeatureRow(feature: feature, included: plan.has(feature)),
          ],
        ),
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  final SubscriptionController controller;

  const _ManageCard({required this.controller});

  Future<void> _confirm(BuildContext context, String title, String message, Future<void> Function() action) async {
    final ok = await ConfirmDialog.show(context, title: title, message: message, confirmLabel: 'subscription.simulate'.tr);
    if (ok) await action();
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = controller.entitlement;
    final subscription = entitlement.subscription!;

    return Card(
      child: Column(
        children: [
          if (!entitlement.expired)
            SwitchListTile(
              secondary: const Icon(Symbols.autorenew),
              title: Text('subscription.automaticRenewal'.tr),
              subtitle: Text(
                subscription.autoRenew
                    ? 'subscription.renewsDate2'.trParams({'ddMMyyyy': DateTimeFormatter.ddMMyyyy(subscription.expiresAt)})
                    : 'subscription.backFreeDate'.trParams({'ddMMyyyy': DateTimeFormatter.ddMMyyyy(subscription.expiresAt)}),
              ),
              value: subscription.autoRenew,
              onChanged: controller.changeAutoRenew,
            ),
          if (controller.isSimulated) ...[
            if (!entitlement.expired) const Divider(height: 1),
            ListTile(
              leading: const Icon(Symbols.timer_off),
              title: Text('subscription.simulateExpirationNow'.tr),
              subtitle: Text('subscription.testSubscriptionExpiresAppGoes'.tr),
              onTap: entitlement.expired
                  ? null
                  : () => _confirm(
                        context,
                        'subscription.simulateExpiration'.tr,
                        'subscription.subscriptionExpiresNowWithoutRenewing'.tr,
                        controller.simulateExpiration,
                      ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Symbols.delete, color: context.colors.error),
              title: Text('subscription.removeTestSubscription'.tr, style: TextStyle(color: context.colors.error)),
              onTap: () => _confirm(
                context,
                'subscription.removeTestSubscription2'.tr,
                'subscription.appGoesBackFreeIf'.tr,
                controller.removeSubscription,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
