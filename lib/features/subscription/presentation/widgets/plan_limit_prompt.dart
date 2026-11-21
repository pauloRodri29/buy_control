import 'package:buy_control/features/subscription/presentation/pages/plans_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Aviso de que o plano não permite a ação, com o atalho para os planos.
/// Usado pelo `FailurePresenter` (limite atingido) e ao tocar num item
/// bloqueado.
class PlanLimitPrompt {
  PlanLimitPrompt._();

  static Future<void> show(String message, {String title = 'subscription.planLimit'}) async {
    final openPlans = await Get.dialog<bool>(
      AlertDialog(
        icon: const Icon(Symbols.workspace_premium),
        title: Text(title.tr),
        content: Text('subscription.upgradeContinueMessage'.trParams({'message': message.tr})),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('subscription.notNow'.tr)),
          FilledButton(onPressed: () => Get.back(result: true), child: Text('subscription.seePlans'.tr)),
        ],
      ),
    );
    if (openPlans == true) await Get.to(() => const PlansPage());
  }

  /// Toque num item que ficou inacessível porque passou do limite do plano.
  static Future<void> showLocked(String planName) {
    return show(
      'subscription.itemLockedBecauseExceedsPlanPlanName'.trParams({'planName': planName}),
      title: 'subscription.itemLocked'.tr,
    );
  }
}
