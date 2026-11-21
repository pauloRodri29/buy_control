import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/features/subscription/data/billing/fake_billing_gateway.dart';
import 'package:buy_control/features/subscription/domain/repositories/billing_gateway.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Checkout" do pagamento simulado: mostra o que seria cobrado e deixa
/// aprovar, recusar ou cancelar. Nenhum valor é cobrado.
class SimulatedPaymentSheet extends StatelessWidget {
  final PurchaseRequest request;

  const SimulatedPaymentSheet({super.key, required this.request});

  /// Implementação do `confirm` do [FakeBillingGateway].
  static Future<SimulatedPaymentDecision> ask(PurchaseRequest request) async {
    final context = Get.context;
    if (context == null) return SimulatedPaymentDecision.cancel;
    final decision = await AppBottomSheet.show<SimulatedPaymentDecision>(
      context,
      child: SimulatedPaymentSheet(request: request),
    );
    return decision ?? SimulatedPaymentDecision.cancel;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    void close(SimulatedPaymentDecision d) => Navigator.of(context).pop(d);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('subscription.confirmSubscription'.tr, style: text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.semantic.warningContainer,
              borderRadius: AppRadius.borderMd,
            ),
            child: Row(
              children: [
                Icon(Symbols.science, color: context.semantic.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'subscription.testModePaymentSimulatedNothing'.tr,
                    style: text.bodySmall?.copyWith(color: colors.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Line(label: 'subscription.plan'.tr, value: request.plan.name),
          _Line(label: 'subscription.billing'.tr, value: request.period.label),
          const Divider(height: AppSpacing.xl),
          _Line(
            label: 'common.total'.tr,
            value: '${request.price.formatted}${request.period.suffix}',
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'subscription.renewsAutomaticallyYouCanTurn'.tr,
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'subscription.approvePayment'.tr,
            icon: Symbols.check_circle,
            onPressed: () => close(SimulatedPaymentDecision.approve),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: 'subscription.simulateDeclinedPayment'.tr,
            onPressed: () => close(SimulatedPaymentDecision.decline),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: AppButton.text(label: 'common.cancel'.tr, onPressed: () => close(SimulatedPaymentDecision.cancel)),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _Line({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : context.text.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: emphasize ? style : context.text.bodyMedium)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
