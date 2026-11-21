sealed class AppFailure {
  final String message;
  const AppFailure(this.message);
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'errors.failedAccessLocalData']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'errors.recordNotFound']);
}

/// Falha ao falar com um serviço remoto (sem internet, tempo esgotado,
/// credencial recusada, erro do servidor). A mensagem já vem pronta para
/// o usuário, dizendo o que aconteceu e o que fazer.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'errors.couldntConnectCheckInternetConnection']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'errors.unexpectedErrorOccurred']);
}

final class NotImplementedFailure extends AppFailure {
  const NotImplementedFailure([super.message = 'common.featureNotAvailableYet']);
}

/// O plano atual não permite a ação (limite de quantidade atingido ou
/// módulo não incluído). A interface oferece ver os planos.
final class PlanLimitFailure extends AppFailure {
  const PlanLimitFailure(super.message);
}

/// O usuário desistiu do pagamento. Não é um erro a mostrar.
final class PurchaseCancelledFailure extends AppFailure {
  const PurchaseCancelledFailure([super.message = 'errors.purchaseCancelled']);
}

/// O pagamento foi recusado.
final class PurchaseDeclinedFailure extends AppFailure {
  const PurchaseDeclinedFailure([super.message = 'errors.paymentWasNotApprovedNothing']);
}
