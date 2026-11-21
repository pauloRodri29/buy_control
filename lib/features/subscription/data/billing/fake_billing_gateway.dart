import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';
import 'package:buy_control/features/subscription/domain/repositories/billing_gateway.dart';

enum SimulatedPaymentDecision { approve, decline, cancel }

/// Pagamento simulado: nada é cobrado. A decisão (aprovar, recusar,
/// cancelar) vem de [confirm], que a interface implementa com uma sheet.
///
/// Quando houver loja, outra implementação de [BillingGateway] entra no
/// lugar desta (registrada no `InitialBinding`), sem mudar nenhuma tela.
class FakeBillingGateway implements BillingGateway {
  final Future<SimulatedPaymentDecision> Function(PurchaseRequest request) confirm;

  const FakeBillingGateway({required this.confirm});

  @override
  bool get isSimulated => true;

  @override
  Future<Result<PurchaseReceipt>> purchase(PurchaseRequest request) async {
    final decision = await confirm(request);
    return switch (decision) {
      SimulatedPaymentDecision.approve => Success(PurchaseReceipt(
          transactionId: 'sim_${IdGenerator.generate()}',
          purchasedAt: DateTime.now(),
          source: SubscriptionSource.simulated,
        )),
      SimulatedPaymentDecision.decline => const Failure(PurchaseDeclinedFailure()),
      SimulatedPaymentDecision.cancel => const Failure(PurchaseCancelledFailure()),
    };
  }
}
