import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_limit_prompt.dart';
import 'package:get/get.dart';

/// Bloqueios do plano para um controller de lista.
///
/// - chame [refreshLocks] dentro do `load()`;
/// - use [isLocked] na tela para esmaecer o item e trocar o toque por
///   [showLockedPrompt];
/// - o `load()` roda de novo sozinho quando o plano muda.
mixin PlanLocks on GetxController {
  ResourceKey get lockResource;

  Future<void> load();

  Set<String> lockedIds = const {};

  SubscriptionController? get _subscription =>
      Get.isRegistered<SubscriptionController>() ? Get.find<SubscriptionController>() : null;

  bool isLocked(String id) => lockedIds.contains(id);

  Future<void> refreshLocks() async {
    lockedIds = await _subscription?.lockedIds(lockResource) ?? const {};
  }

  void showLockedPrompt() {
    PlanLimitPrompt.showLocked(_subscription?.plan.name ?? 'atual');
  }

  void _onPlanChanged() => load();

  @override
  void onInit() {
    super.onInit();
    _subscription?.addPlanListener(_onPlanChanged);
  }

  @override
  void onClose() {
    _subscription?.removePlanListener(_onPlanChanged);
    super.onClose();
  }
}
