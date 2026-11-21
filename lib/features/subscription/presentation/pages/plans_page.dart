import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/subscription/domain/custom_plan_pricing.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/pages/custom_plan_builder_page.dart';
import 'package:buy_control/features/subscription/presentation/widgets/coupon_field.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_feature_row.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Todos os planos para assinar ou trocar: alternância mensal/anual e um
/// card por plano, com o atual destacado. Aberta pelo "Fazer upgrade" de
/// "Meu plano" e pelos avisos de limite.
class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final _controller = Get.find<SubscriptionController>();
  late BillingPeriod _period = _controller.entitlement.subscription?.period ?? BillingPeriod.monthly;

  Future<void> _choose(PlanDefinition plan) async {
    final entitlement = _controller.entitlement;
    final current = entitlement.plan;
    final subscription = entitlement.subscription;

    if (plan.isFree) {
      if (subscription == null || entitlement.expired) return;
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'subscription.goBackFreePlan'.tr,
        message: 'subscription.renewalWillTurnedOffPlanNameDate'.trParams({
          'name': current.name,
          'ddMMyyyy': DateTimeFormatter.ddMMyyyy(subscription.expiresAt),
        }),
        confirmLabel: 'subscription.turnOffRenewal'.tr,
      );
      if (confirmed) await _controller.changeAutoRenew(false);
      return;
    }

    if (plan.rank < current.rank) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'subscription.switchName3'.trParams({'name': plan.name}),
        message: 'subscription.anythingOverLimitsGetsLockedName'.trParams({'name': plan.name}),
        confirmLabel: 'subscription.changePlan'.tr,
        isDestructive: false,
      );
      if (!confirmed) return;
    }
    final ok = await _controller.subscribe(plan, _period);
    if (ok && mounted) Navigator.of(context).maybePop();
  }

  /// Abre o montador; se o usuário assinar lá, volta direto para "Meu plano".
  Future<void> _openBuilder() async {
    final subscribed = await Get.to<bool>(() => CustomPlanBuilderPage(initialPeriod: _period));
    if (subscribed == true && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('subscription.plans'.tr)),
      body: GetBuilder<SubscriptionController>(
        builder: (controller) {
          final entitlement = controller.entitlement;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Text('subscription.plansSubtitle'.tr, style: context.text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: SegmentedButton<BillingPeriod>(
                  showSelectedIcon: false,
                  segments: [
                    for (final p in BillingPeriod.values) ButtonSegment(value: p, label: Text(p.label)),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
              ),
              if (controller.isSimulated) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.science, size: 14, color: context.semantic.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Text('subscription.testModeShort'.tr, style: context.text.labelSmall),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const CouponField(),
              const SizedBox(height: AppSpacing.md),
              for (final plan in PlanCatalog.all) ...[
                _PlanOptionCard(
                  plan: plan,
                  period: _period,
                  entitlement: entitlement,
                  coupon: plan.isFree ? null : controller.couponFor(plan.id),
                  busy: controller.purchasing,
                  onChoose: () => _choose(plan),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _CustomPlanCard(entitlement: entitlement, onOpen: _openBuilder),
            ],
          );
        },
      ),
    );
  }
}

/// Um plano na lista: preço no período escolhido, limites, módulos e a
/// ação (assinar, trocar, voltar ao Grátis).
class _PlanOptionCard extends StatelessWidget {
  final PlanDefinition plan;
  final BillingPeriod period;
  final Entitlement entitlement;

  /// Cupom aplicado que vale para este plano (mostra o preço com desconto).
  final Coupon? coupon;
  final bool busy;
  final VoidCallback onChoose;

  const _PlanOptionCard({
    required this.plan,
    required this.period,
    required this.entitlement,
    this.coupon,
    required this.busy,
    required this.onChoose,
  });

  static const _highlights = [
    ResourceKey.boxes,
    ResourceKey.products,
    ResourceKey.planBoards,
    ResourceKey.categories,
  ];

  ({String label, bool enabled, bool primary}) _action() {
    final current = entitlement.plan;
    final subscription = entitlement.expired ? null : entitlement.subscription;
    final isCurrent = plan.id == current.id;

    if (plan.isFree) {
      if (current.isFree) return (label: 'subscription.currentPlan2'.tr, enabled: false, primary: false);
      if (subscription != null && !subscription.autoRenew) {
        return (label: 'subscription.backFreeExpiration'.tr, enabled: false, primary: false);
      }
      return (label: 'subscription.backFree'.tr, enabled: true, primary: false);
    }
    if (isCurrent && subscription?.period == period) {
      return (label: 'subscription.currentPlan2'.tr, enabled: false, primary: false);
    }
    if (isCurrent) {
      return (
        label: 'subscription.switchName2'.trParams({'toLowerCase': period.label.toLowerCase()}),
        enabled: true,
        primary: true,
      );
    }
    if (plan.rank > current.rank) {
      return (label: 'subscription.subscribeName'.trParams({'name': plan.name}), enabled: true, primary: true);
    }
    return (label: 'subscription.switchName'.trParams({'name': plan.name}), enabled: true, primary: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isCurrent = plan.id == entitlement.plan.id;
    final action = _action();
    final price = plan.priceFor(period);
    final savings = plan.yearlySavings;

    final border = isCurrent
        ? BorderSide(color: colors.primary, width: 2)
        : plan.recommended
            ? BorderSide(color: AppBrand.amber.withValues(alpha: 0.8), width: 1.5)
            : BorderSide(color: colors.outlineVariant);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg, side: border),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: AppSpacing.sm),
                if (isCurrent)
                  _Tag(label: 'subscription.current'.tr, background: colors.primary, foreground: colors.onPrimary)
                else if (plan.recommended)
                  _Tag(label: 'subscription.mostPopular'.tr, background: AppBrand.amber, foreground: AppBrand.terminal),
              ],
            ),
            const SizedBox(height: 2),
            Text(plan.tagline, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (coupon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      price.formatted,
                      style: text.bodyMedium?.copyWith(decoration: TextDecoration.lineThrough),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  plan.isFree ? 'subscription.free'.tr : (coupon?.apply(price) ?? price).formatted,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colors.primary),
                ),
                if (!plan.isFree) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(period.suffix, style: text.bodyMedium),
                  ),
                ],
              ],
            ),
            if (!plan.isFree && period == BillingPeriod.yearly && savings.cents > 0)
              Text(
                'subscription.savePerYearAmount'.trParams({'formatted': savings.formatted}),
                style: text.bodySmall?.copyWith(color: context.semantic.success, fontWeight: FontWeight.w600),
              )
            else if (!plan.isFree && period == BillingPeriod.monthly)
              Text('subscription.yrAmount'.trParams({'formatted': plan.yearlyPrice.formatted}), style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final resource in _highlights) _LimitChip(resource: resource, limit: plan.limitOf(resource)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final feature in FeatureKey.values.where((f) => f != FeatureKey.backupManual && plan.has(f)))
              PlanFeatureRow(feature: feature, included: true, dense: true),
            const SizedBox(height: AppSpacing.lg),
            action.primary
                ? AppButton(label: action.label, onPressed: action.enabled && !busy ? onChoose : null)
                : AppButton.secondary(label: action.label, onPressed: action.enabled && !busy ? onChoose : null),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Tag({required this.label, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LimitChip extends StatelessWidget {
  final ResourceKey resource;
  final int? limit;

  const _LimitChip({required this.resource, required this.limit});

  @override
  Widget build(BuildContext context) {
    final limit = this.limit;
    final label = switch ((resource, limit)) {
      (ResourceKey.boxes, null) => 'subscription.unlimitedBoxes'.tr,
      (ResourceKey.categories, null) => 'subscription.unlimitedCategories'.tr,
      (ResourceKey.products, null) => 'subscription.unlimitedProducts'.tr,
      (ResourceKey.planBoards, null) => 'subscription.unlimitedBoards'.tr,
      (ResourceKey.boxes, 1) => 'subscription.n1Box'.tr,
      (ResourceKey.boxes, _) => 'subscription.boxesLimit'.trParams({'limit': '$limit'}),
      (_, null) => 'subscription.unlimitedCount'.trParams({'plural': resource.plural}),
      (_, 1) => '1 ${resource.singular}',
      _ => '$limit ${resource.plural}',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.borderSm,
      ),
      child: Text(
        label,
        style: context.text.labelMedium?.copyWith(color: context.colors.onSurface),
      ),
    );
  }
}

/// Entrada do plano Personalizado: explica a ideia e leva ao montador.
/// Quando é o plano atual, mostra o preço e vira "Ajustar meu plano".
class _CustomPlanCard extends StatelessWidget {
  final Entitlement entitlement;
  final VoidCallback onOpen;

  const _CustomPlanCard({required this.entitlement, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isCurrent = !entitlement.expired && entitlement.plan.id == CustomPlanPricing.planId;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: isCurrent
            ? BorderSide(color: colors.primary, width: 2)
            : BorderSide(color: colors.outlineVariant, style: BorderStyle.solid),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.tune, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('subscription.customPlan'.tr, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: AppSpacing.sm),
                if (isCurrent)
                  _Tag(label: 'subscription.current'.tr, background: colors.primary, foreground: colors.onPrimary),
              ],
            ),
            const SizedBox(height: 2),
            Text('subscription.customPlanTagline'.tr, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            if (isCurrent)
              Text(
                '${entitlement.subscription!.pricePaid.formatted}${entitlement.subscription!.period.suffix}',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colors.primary),
              )
            else
              Text(
                'subscription.customFromPrice'.trParams({'price': CustomPlanPricing.minMonthly.formatted}),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colors.primary),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text('subscription.customCardDescription'.tr, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: isCurrent ? 'subscription.adjustMyPlan'.tr : 'subscription.buildMyPlan'.tr,
              icon: Symbols.tune,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}
