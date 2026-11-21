import 'package:get/get.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_limit_prompt.dart';

/// Ponte entre as falhas do domínio ([AppFailure]) e o que o usuário vê.
///
/// - [present]: só a mensagem, para estados de erro de tela/formulário.
/// - [show]: mostra a falha como aviso ([AppFeedback]); é o caminho único
///   para erros de ações (excluir, arquivar, exportar...).
class FailurePresenter {
  FailurePresenter._();

  /// As mensagens padrão das falhas são chaves de tradução; `.tr` as
  /// traduz (as que já vêm traduzidas passam intactas).
  static String present(AppFailure failure) => failure.message.tr;

  static void show(AppFailure failure, {String? title}) {
    switch (failure) {
      case NotImplementedFailure():
        AppFeedback.info(present(failure), title: title ?? 'common.comingSoon'.tr);
      case ValidationFailure():
        AppFeedback.error(present(failure), title: title ?? 'errors.checkData'.tr);
      case NetworkFailure():
        AppFeedback.error(present(failure), title: title ?? 'errors.connectionFailed'.tr);
      case PlanLimitFailure():
        PlanLimitPrompt.show(present(failure));
      case PurchaseCancelledFailure():
        break;
      case PurchaseDeclinedFailure():
        AppFeedback.error(present(failure), title: title ?? 'errors.paymentDeclined'.tr);
      case CacheFailure() || NotFoundFailure() || UnknownFailure():
        AppFeedback.error(present(failure), title: title ?? 'common.couldntComplete'.tr);
    }
  }

  /// Mostra a falha de [result], se houver. Devolve `true` em caso de sucesso.
  static bool showIfFailure(Result<Object?> result, {String? title}) {
    final failure = result.failureOrNull;
    if (failure != null) show(failure, title: title);
    return failure == null;
  }
}
