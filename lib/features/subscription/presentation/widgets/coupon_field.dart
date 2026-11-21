import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/features/subscription/domain/custom_plan_pricing.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Tem um cupom?": abre o campo do código; aplicado, vira um selo com o
/// desconto e o botão de remover. O cupom fica no controller, então vale
/// na tela de planos e no montador.
class CouponField extends StatefulWidget {
  const CouponField({super.key});

  /// Texto do desconto ("20% de desconto", "R$ 5,00 de desconto").
  static String describe(Coupon coupon) {
    final value = switch (coupon.kind) {
      CouponKind.percent => 'subscription.couponPercentOff'.trParams({'value': '${coupon.percent}'}),
      CouponKind.fixed => 'subscription.couponFixedOff'.trParams({'value': coupon.amount.formatted}),
    };
    final onlyCustom = coupon.planIds?.length == 1 && coupon.planIds!.contains(CustomPlanPricing.planId);
    return onlyCustom ? '$value · ${'subscription.couponOnlyCustom'.tr}' : value;
  }

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();
  bool _open = false;
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply(SubscriptionController subscription) async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final error = await subscription.applyCoupon(_controller.text);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _error = error;
      if (error == null) {
        _open = false;
        _controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (subscription) {
        final coupon = subscription.coupon;
        if (coupon != null) return _AppliedCoupon(coupon: coupon, onRemove: subscription.removeCoupon);

        if (!_open) {
          return Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _open = true),
              icon: const Icon(Symbols.sell, size: 18),
              label: Text('subscription.couponHave'.tr),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'subscription.couponHint'.tr,
                  errorText: _error,
                  prefixIcon: const Icon(Symbols.sell, size: 18),
                ),
                onSubmitted: (_) => _apply(subscription),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: FilledButton(
                onPressed: _checking ? null : () => _apply(subscription),
                child: Text('common.apply'.tr),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppliedCoupon extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onRemove;

  const _AppliedCoupon({required this.coupon, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
      decoration: BoxDecoration(color: semantic.successContainer, borderRadius: AppRadius.borderMd),
      child: Row(
        children: [
          Icon(Symbols.sell, size: 18, color: semantic.success, fill: 1),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: coupon.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: '  ${CouponField.describe(coupon)}'),
              ]),
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface),
            ),
          ),
          IconButton(
            tooltip: 'subscription.couponRemove'.tr,
            visualDensity: VisualDensity.compact,
            icon: Icon(Symbols.close, size: 18, color: context.colors.onSurfaceVariant),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
