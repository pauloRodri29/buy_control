import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/transaction_sort.dart';

class GetTransactionsByBox {
  final TransactionRepository repository;
  const GetTransactionsByBox(this.repository);

  Future<Result<List<TransactionEntity>>> call(
    String boxId, {
    TransactionSort sort = TransactionSort.newest,
  }) async {
    final result = await repository.getAll(boxId: boxId);
    return result.fold((transactions) {
      final sorted = [...transactions];
      switch (sort) {
        case TransactionSort.newest:
          sorted.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        case TransactionSort.oldest:
          sorted.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
        case TransactionSort.highestValue:
          sorted.sort((a, b) => b.total.cents.compareTo(a.total.cents));
        case TransactionSort.lowestValue:
          sorted.sort((a, b) => a.total.cents.compareTo(b.total.cents));
        case TransactionSort.name:
          sorted.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
        case TransactionSort.highestQuantity:
          sorted.sort((a, b) => _totalQuantity(b).compareTo(_totalQuantity(a)));
      }
      return Success(sorted);
    }, (f) => Failure(f));
  }

  double _totalQuantity(TransactionEntity transaction) {
    return transaction.items.fold(0.0, (sum, item) => sum + item.quantity);
  }
}
