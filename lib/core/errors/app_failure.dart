sealed class AppFailure {
  final String message;
  const AppFailure(this.message);
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Falha ao acessar os dados locais.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Registro não encontrado.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Ocorreu um erro inesperado.']);
}

final class NotImplementedFailure extends AppFailure {
  const NotImplementedFailure([super.message = 'Este recurso ainda não está disponível.']);
}
