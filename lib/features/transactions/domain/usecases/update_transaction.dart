import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class UpdateTransaction {
  final TransactionRepository repository;
  const UpdateTransaction(this.repository);

  Future<Result<void>> call(TransactionEntity transaction) async {
    // Lançamentos que já pertencem a um Fechamento estão congelados —
    // editá-los mudaria silenciosamente um relatório histórico já emitido.
    if (transaction.isClosed) {
      return Failure(
        ValidationFailure('transactions.entryPartClosingCanNo'.tr),
      );
    }
    if (!Validators.isNotBlank(transaction.boxId)) {
      return Failure(ValidationFailure('transactions.boxRequired'.tr));
    }
    if (transaction.items.isEmpty) {
      return Failure(
        ValidationFailure('transactions.addLeastOneItemOne'.tr),
      );
    }
    for (final item in transaction.items) {
      if (!Validators.isPositive(item.quantity)) {
        return Failure(
          ValidationFailure('transactions.invalidQuantityNameSnapshot'.trParams({'nameSnapshot': item.nameSnapshot})),
        );
      }
      if (item.unitPrice.cents < 0) {
        return Failure(
          ValidationFailure('transactions.invalidUnitPriceNameSnapshot'.trParams({'nameSnapshot': item.nameSnapshot})),
        );
      }
    }
    if (transaction.total.isNegative) {
      return Failure(
        ValidationFailure('transactions.discountCantMakeTotalNegative'.tr),
      );
    }

    return repository.update(transaction);
  }
}
