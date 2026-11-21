import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';

class PurchaseRequest {
  final PlanDefinition plan;
  final BillingPeriod period;
  final Money price;

  const PurchaseRequest({required this.plan, required this.period, required this.price});
}

class PurchaseReceipt {
  final String transactionId;
  final DateTime purchasedAt;
  final SubscriptionSource source;

  const PurchaseReceipt({required this.transactionId, required this.purchasedAt, required this.source});
}

/// Quem efetivamente cobra. Hoje: pagamento simulado. Depois: loja
/// (Google Play / App Store), via RevenueCat ou integração própria.
///
/// Falhas esperadas: [PurchaseCancelledFailure] (o usuário desistiu) e
/// [PurchaseDeclinedFailure] (pagamento recusado).
abstract class BillingGateway {
  /// `true` quando nada é cobrado de verdade (mostra o aviso "Modo de teste").
  bool get isSimulated;

  Future<Result<PurchaseReceipt>> purchase(PurchaseRequest request);
}
