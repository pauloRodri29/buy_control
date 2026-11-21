import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class DeleteTransaction {
  final TransactionRepository repository;
  const DeleteTransaction(this.repository);

  Future<Result<void>> call(String id) async {
    final existing = await repository.getById(id);
    return existing.fold((transaction) {
      if (transaction.isClosed) {
        return Future.value(Failure(
          ValidationFailure('transactions.entryPartClosingCanNo2'.tr),
        ));
      }
      final now = DateTime.now();
      return repository.update(transaction.copyWith(deletedAt: now, updatedAt: now));
    }, (f) async => Failure(f));
  }
}
