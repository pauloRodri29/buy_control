import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';
import 'package:buy_control/features/subscription/domain/entities/custom_plan_config.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/repositories/billing_gateway.dart';
import 'package:buy_control/features/subscription/domain/repositories/coupon_repository.dart';
import 'package:buy_control/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:buy_control/features/subscription/domain/resource_inventory.dart';
import 'package:buy_control/features/subscription/domain/usecases/coupon_usecases.dart';
import 'package:buy_control/features/subscription/domain/usecases/plan_access_usecases.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';
import 'package:buy_control/features/subscription/domain/usecases/subscription_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Plano em vigor do usuário logado, mantido em memória para as travas
/// ([QuotaGuard]) e para as telas. Registrado como permanente no
/// `InitialBinding` e carregado quando o app principal abre.
///
/// Quando o plano muda (assinou, trocou, venceu), avisa quem se inscreveu
/// em [addPlanListener] — as listas recarregam e recalculam os bloqueios.
class SubscriptionController extends GetxController implements EntitlementSource {
  final GetEntitlement getEntitlement;
  final PurchasePlan purchasePlan;
  final SetAutoRenew setAutoRenew;
  final GetPlanUsage getPlanUsage;
  final ResourceInventory inventory;
  final SubscriptionRepository repository;
  final BillingGateway billing;
  final ValidateCoupon validateCoupon;
  final CouponRepository coupons;

  SubscriptionController({
    required this.getEntitlement,
    required this.purchasePlan,
    required this.setAutoRenew,
    required this.getPlanUsage,
    required this.inventory,
    required this.repository,
    required this.billing,
    required this.validateCoupon,
    required this.coupons,
  });

  @override
  Entitlement entitlement = Entitlement.free;
  Map<ResourceKey, int> usage = {};
  ViewStatus status = ViewStatus.initial;
  bool purchasing = false;

  /// Cupom aplicado na tela de planos/montador (vale até assinar ou remover).
  Coupon? coupon;

  final _planListeners = <VoidCallback>[];

  PlanDefinition get plan => entitlement.plan;
  bool get isSimulated => billing.isSimulated;

  String? get _userId => Get.find<AuthController>().currentUser?.id;

  void addPlanListener(VoidCallback listener) => _planListeners.add(listener);

  void removePlanListener(VoidCallback listener) => _planListeners.remove(listener);

  Future<void> load() async {
    final userId = _userId;
    final previous = entitlement;
    if (userId == null) {
      entitlement = Entitlement.free;
    } else {
      final result = await getEntitlement(userId);
      result.fold((data) => entitlement = data, FailurePresenter.show);
    }
    status = ViewStatus.success;
    update();
    if (_signature(previous) != _signature(entitlement)) _notifyPlanChanged();
  }

  /// Uso de cada recurso, para a tela "Meu plano".
  Future<void> loadUsage() async {
    final result = await getPlanUsage();
    result.fold((data) => usage = data, (_) {});
    update();
  }

  late final _getLockedIds = GetLockedIds(source: this, inventory: inventory);

  /// Ids que passaram do limite do plano e estão inacessíveis.
  Future<Set<String>> lockedIds(ResourceKey resource) => _getLockedIds(resource);

  /// Valida e aplica um cupom. Devolve a mensagem de erro ou `null`.
  Future<String?> applyCoupon(String code) async {
    final userId = _userId;
    if (userId == null) return null;
    final result = await validateCoupon(code, userId: userId);
    return result.fold((found) {
      coupon = found;
      update();
      return null;
    }, FailurePresenter.present);
  }

  void removeCoupon() {
    coupon = null;
    update();
  }

  /// Cupom aplicado, se ele vale para [planId].
  Coupon? couponFor(String planId) => coupon != null && coupon!.appliesTo(planId) ? coupon : null;

  /// Assina [plan] (pagamento simulado ou pela loja), com o cupom aplicado
  /// quando ele vale para o plano. Com [customConfig], assina o
  /// Personalizado. Devolve `true` se deu certo.
  Future<bool> subscribe(PlanDefinition plan, BillingPeriod period, {CustomPlanConfig? customConfig}) async {
    final userId = _userId;
    if (userId == null || purchasing) return false;

    purchasing = true;
    update();
    final result = await purchasePlan(
      userId: userId,
      plan: plan,
      period: period,
      customConfig: customConfig,
      coupon: couponFor(plan.id),
    );
    purchasing = false;

    final ok = FailurePresenter.showIfFailure(result, title: 'subscription.couldntSubscribe'.tr);
    if (ok) {
      coupon = null;
      final name = result.dataOrNull == null ? plan.name : Entitlement.resolve(result.dataOrNull).plan.name;
      AppFeedback.success('subscription.youreNowPlanName'.trParams({'name': name}), title: 'subscription.planActivated'.tr);
    }
    await _reload();
    return ok;
  }

  /// Desliga (ou religa) a renovação. Desligada, o plano segue até o
  /// vencimento e depois volta ao Grátis.
  Future<void> changeAutoRenew(bool enabled) async {
    final subscription = entitlement.subscription;
    if (subscription == null) return;
    FailurePresenter.showIfFailure(await setAutoRenew(subscription, enabled: enabled));
    await _reload();
  }

  /// Teste: faz a assinatura vencer agora, sem renovar.
  Future<void> simulateExpiration() async {
    final subscription = entitlement.subscription;
    if (subscription == null) return;
    final expired = subscription.copyWith(expiresAt: DateTime.now(), autoRenew: false);
    FailurePresenter.showIfFailure(await repository.save(expired));
    await _reload();
  }

  /// Teste: apaga a assinatura (volta ao Grátis como se nunca tivesse assinado).
  Future<void> removeSubscription() async {
    final userId = _userId;
    if (userId == null) return;
    FailurePresenter.showIfFailure(await repository.clear(userId));
    await coupons.clearRedeemed(userId);
    coupon = null;
    await _reload();
  }

  Future<void> _reload() async {
    await load();
    await loadUsage();
  }

  /// Muda quando o plano ou a configuração do Personalizado mudam.
  static String _signature(Entitlement e) => '${e.plan.id}|${e.subscription?.customConfig?.toMap()}';

  void _notifyPlanChanged() {
    for (final listener in List.of(_planListeners)) {
      listener();
    }
  }
}
