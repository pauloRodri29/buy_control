import 'package:buy_control/core/errors/app_failure.dart';

/// Converte uma [AppFailure] do domínio em uma mensagem apresentável ao
/// usuário, usada pelos estados de erro da apresentação.
class FailurePresenter {
  FailurePresenter._();

  static String present(AppFailure failure) => failure.message;
}
