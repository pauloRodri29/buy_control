import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class UpdateTransaction {
  final TransactionRepository repository;
  const UpdateTransaction(this.repository);

  Future<Result<void>> call(TransactionEntity transaction) async {
    if (!Validators.isNotBlank(transaction.boxId)) {
      return const Failure(ValidationFailure('Box é obrigatória.'));
    }
    if (transaction.items.isEmpty) {
      return const Failure(
        ValidationFailure('Informe ao menos um item ou lançamento avulso.'),
      );
    }
    for (final item in transaction.items) {
      if (!Validators.isPositive(item.quantity)) {
        return Failure(
          ValidationFailure('Quantidade inválida para "${item.nameSnapshot}".'),
        );
      }
      if (item.unitPrice.cents < 0) {
        return Failure(
          ValidationFailure('Preço unitário inválido para "${item.nameSnapshot}".'),
        );
      }
    }
    if (transaction.total.isNegative) {
      return const Failure(
        ValidationFailure('O desconto não pode tornar o total negativo.'),
      );
    }

    return repository.update(transaction);
  }
}
