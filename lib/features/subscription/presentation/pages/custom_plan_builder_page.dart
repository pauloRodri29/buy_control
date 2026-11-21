import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/subscription/domain/custom_plan_pricing.dart';
import 'package:buy_control/features/subscription/domain/entities/custom_plan_config.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/widgets/coupon_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Montador do plano Personalizado: parte do Grátis e o usuário acrescenta
/// módulos e pacotes de quantidade. O total é a soma dos itens e aparece
/// na barra de baixo, atualizado a cada toque.
class CustomPlanBuilderPage extends StatefulWidget {
  final BillingPeriod initialPeriod;

  const CustomPlanBuilderPage({super.key, this.initialPeriod = BillingPeriod.monthly});

  @override
  State<CustomPlanBuilderPage> createState() => _CustomPlanBuilderPageState();
}

class _CustomPlanBuilderPageState extends State<CustomPlanBuilderPage> {
  final _subscription = Get.find<SubscriptionController>();
  late BillingPeriod _period = widget.initialPeriod;

  /// Começa pela configuração atual, se o usuário já está no Personalizado.
  late CustomPlanConfig _config = _currentConfig ?? CustomPlanConfig.empty;

  CustomPlanConfig? get _currentConfig {
    final entitlement = _subscription.entitlement;
    if (entitlement.expired || entitlement.plan.id != CustomPlanPricing.planId) return null;
    return entitlement.subscription?.customConfig;
  }

  bool get _isCurrent {
    final current = _currentConfig;
    return current != null &&
        _subscription.entitlement.subscription?.period == _period &&
        current.toMap().toString() == _config.toMap().toString();
  }

  void _setPacks(ResourceKey resource, int value) => setState(() => _config = _config.withPacks(resource, value));

  Future<void> _subscribe() async {
    final plan = CustomPlanPricing.buildPlan(_config);
    final ok = await _subscription.subscribe(plan, _period, customConfig: _config);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _subscribeStandard(PlanDefinition plan) async {
    final ok = await _subscription.subscribe(plan, _period);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (controller) {
        final monthly = CustomPlanPricing.monthlyPrice(_config);
        final overCap = monthly > CustomPlanPricing.maxMonthly;
        final price = CustomPlanPricing.priceFor(_config, _period);
        final coupon = controller.couponFor(CustomPlanPricing.planId);
        final total = coupon?.apply(price) ?? price;
        final cheaper = CustomPlanPricing.cheaperStandardPlan(_config, _period, price);

        return Scaffold(
          appBar: AppBar(title: Text('subscription.builderTitle'.tr)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            children: [
              Text('subscription.builderIntro'.tr, style: context.text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: SegmentedButton<BillingPeriod>(
                  showSelectedIcon: false,
                  segments: [for (final p in BillingPeriod.values) ButtonSegment(value: p, label: Text(p.label))],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('subscription.modules'.tr),
              Card(
                child: Column(
                  children: [
                    for (final feature in PlanCatalog.free.features.where((f) => f != FeatureKey.backupManual))
                      ListTile(
                        dense: true,
                        leading: Icon(Symbols.check_circle, fill: 1, color: context.semantic.success, size: 20),
                        title: Text(feature.label),
                        trailing: Text('subscription.includedFree'.tr, style: context.text.labelMedium),
                      ),
                    const Divider(height: 1),
                    for (final entry in CustomPlanPricing.modulePrices.entries)
                      SwitchListTile(
                        value: _config.modules.contains(entry.key),
                        onChanged: (v) => setState(() => _config = _config.withModule(entry.key, v)),
                        title: Text(entry.key.label),
                        subtitle: Text('subscription.plusPerMonth'.trParams({'price': entry.value.formatted})),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('subscription.quantities'.tr),
              Card(
                child: Column(
                  children: [
                    for (final (i, pack) in CustomPlanPricing.packs.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _PackRow(
                        pack: pack,
                        config: _config,
                        onChanged: (value) => _setPacks(pack.resource, value),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const CouponField(),
              if (overCap) ...[
                const SizedBox(height: AppSpacing.md),
                _Hint(
                  icon: Symbols.info,
                  text: 'subscription.customOverCap'.trParams({'max': CustomPlanPricing.maxMonthly.formatted}),
                  actionLabel: 'subscription.subscribeName'.trParams({'name': PlanCatalog.premium.name}),
                  onAction: controller.purchasing ? null : () => _subscribeStandard(PlanCatalog.premium),
                ),
              ] else if (cheaper != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Hint(
                  icon: Symbols.lightbulb,
                  text: 'subscription.cheaperPlanHint'.trParams({
                    'name': cheaper.name,
                    'price': '${cheaper.priceFor(_period).formatted}${_period.suffix}',
                  }),
                  actionLabel: 'subscription.subscribeName'.trParams({'name': cheaper.name}),
                  onAction: controller.purchasing ? null : () => _subscribeStandard(cheaper),
                ),
              ],
            ],
          ),
          bottomNavigationBar: _SummaryBar(
            config: _config,
            period: _period,
            price: price,
            total: total,
            couponCode: coupon?.code,
            enabled: !overCap && !_isCurrent && !controller.purchasing,
            buttonLabel: _isCurrent
                ? 'subscription.currentPlan2'.tr
                : 'subscription.subscribeFor'.trParams({'price': '${total.formatted}${_period.suffix}'}),
            onSubscribe: _subscribe,
          ),
        );
      },
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

/// Um recurso: limite resultante, preço e o stepper de pacotes, com a
/// opção "Ilimitado".
class _PackRow extends StatelessWidget {
  final ResourcePack pack;
  final CustomPlanConfig config;
  final ValueChanged<int> onChanged;

  const _PackRow({required this.pack, required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resource = pack.resource;
    final unlimited = config.isUnlimited(resource);
    final packs = config.packsOf(resource);
    final limit = CustomPlanPricing.limitFor(config, resource);
    final freeLimit = PlanCatalog.free.limitOf(resource) ?? 0;
    final cost = CustomPlanPricing.resourceCost(config, resource);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(resource.label, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  cost.isZero ? 'subscription.includedFree'.tr : '+${cost.formatted}',
                  style: context.text.labelLarge?.copyWith(color: cost.isZero ? null : colors.primary),
                ),
              ),
            ],
          ),
          Text(
            unlimited
                ? 'subscription.unlimitedLabel'.tr
                : 'subscription.upToWithFree'.trParams({'total': '$limit', 'free': '$freeLimit'}),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                tooltip: 'subscription.lessPack'.tr,
                onPressed: unlimited || packs == 0 ? null : () => onChanged(packs - 1),
                icon: const Icon(Symbols.remove, size: 18),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  unlimited ? '∞' : '+${packs * pack.size}',
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                tooltip: 'subscription.morePack'.trParams({'size': '${pack.size}', 'price': pack.price.formatted}),
                onPressed: unlimited || packs >= pack.maxPacks ? null : () => onChanged(packs + 1),
                icon: const Icon(Symbols.add, size: 18),
              ),
              const Spacer(),
              FilterChip(
                label: Text('subscription.unlimitedLabel'.tr),
                selected: unlimited,
                onSelected: (v) => onChanged(v ? CustomPlanConfig.unlimited : 0),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'subscription.packInfo'.trParams({
                'size': '${pack.size}',
                'price': pack.price.formatted,
                'unlimited': pack.unlimitedPrice.formatted,
              }),
              style: context.text.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback? onAction;

  const _Hint({required this.icon, required this.text, required this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppBrand.amber.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppBrand.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: context.colors.tertiary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(text, style: context.text.bodyMedium)),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

/// Barra fixa de baixo: total no período e o botão de assinar; tocando no
/// total abre o resumo linha a linha.
class _SummaryBar extends StatefulWidget {
  final CustomPlanConfig config;
  final BillingPeriod period;
  final Money price;
  final Money total;
  final String? couponCode;
  final bool enabled;
  final String buttonLabel;
  final VoidCallback onSubscribe;

  const _SummaryBar({
    required this.config,
    required this.period,
    required this.price,
    required this.total,
    required this.couponCode,
    required this.enabled,
    required this.buttonLabel,
    required this.onSubscribe,
  });

  @override
  State<_SummaryBar> createState() => _SummaryBarState();
}

class _SummaryBarState extends State<_SummaryBar> {
  bool _expanded = false;

  List<(String, Money)> _lines() {
    final config = widget.config;
    return [
      ('subscription.baseFee'.tr, CustomPlanPricing.baseFee),
      for (final feature in config.modules) (feature.label, CustomPlanPricing.moduleCost(feature)),
      for (final pack in CustomPlanPricing.packs)
        if (config.packsOf(pack.resource) != 0)
          (
            config.isUnlimited(pack.resource)
                ? '${pack.resource.label} · ${'subscription.unlimitedLabel'.tr}'
                : '${pack.resource.label} · +${config.packsOf(pack.resource) * pack.size}',
            CustomPlanPricing.resourceCost(config, pack.resource),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final discount = widget.price - widget.total;
    final monthlySum = _lines().fold(Money.zero, (sum, line) => sum + line.$2);
    final minimumApplied = monthlySum < CustomPlanPricing.minMonthly;

    return Material(
      color: colors.surfaceContainer,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: AppRadius.borderSm,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Text('subscription.summary'.tr, style: text.labelLarge),
                      Icon(_expanded ? Symbols.expand_more : Symbols.expand_less, size: 18),
                      const Spacer(),
                      if (!discount.isZero) ...[
                        Text(
                          widget.price.formatted,
                          style: text.bodySmall?.copyWith(decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        widget.total.formatted,
                        style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: colors.primary),
                      ),
                      Text(widget.period.suffix, style: text.bodyMedium),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: !_expanded
                    ? const SizedBox(width: double.infinity)
                    : ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.35),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const Divider(),
                              for (final (label, amount) in _lines()) _Line(label: label, amount: amount),
                              if (minimumApplied)
                                _Line(
                                  label: 'subscription.minimumPrice'.tr,
                                  amount: CustomPlanPricing.minMonthly - monthlySum,
                                ),
                              if (widget.period == BillingPeriod.yearly)
                                _Line(
                                  label: 'subscription.yearlyTenMonths'.tr,
                                  amount: widget.price,
                                  emphasize: true,
                                ),
                              if (!discount.isZero)
                                _Line(
                                  label: 'subscription.couponLine'.trParams({'code': widget.couponCode ?? ''}),
                                  amount: Money(-discount.cents),
                                  color: context.semantic.success,
                                ),
                              const Divider(),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(label: widget.buttonLabel, onPressed: widget.enabled ? widget.onSubscribe : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final Money amount;
  final bool emphasize;
  final Color? color;

  const _Line({required this.label, required this.amount, this.emphasize = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = (emphasize ? context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700) : context.text.bodyMedium)
        ?.copyWith(color: color);
    final value = amount.isNegative ? '− ${Money(-amount.cents).formatted}' : amount.formatted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
