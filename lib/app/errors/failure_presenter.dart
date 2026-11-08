import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';

/// Ponte entre as falhas do domínio ([AppFailure]) e o que o usuário vê.
///
/// - [present]: só a mensagem, para estados de erro de tela/formulário.
/// - [show]: mostra a falha como aviso ([AppFeedback]); é o caminho único
///   para erros de ações (excluir, arquivar, exportar...).
class FailurePresenter {
  FailurePresenter._();

  static String present(AppFailure failure) => failure.message;

  static void show(AppFailure failure, {String? title}) {
    switch (failure) {
      case NotImplementedFailure():
        AppFeedback.info(present(failure), title: title ?? 'Em breve');
      case ValidationFailure():
        AppFeedback.error(present(failure), title: title ?? 'Confira os dados');
      case CacheFailure() || NotFoundFailure() || UnknownFailure():
        AppFeedback.error(present(failure), title: title ?? 'Não foi possível concluir');
    }
  }

  /// Mostra a falha de [result], se houver. Devolve `true` em caso de sucesso.
  static bool showIfFailure(Result<Object?> result, {String? title}) {
    final failure = result.failureOrNull;
    if (failure != null) show(failure, title: title);
    return failure == null;
  }
}
