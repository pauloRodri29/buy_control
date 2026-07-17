import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class AddProductsToTransaction {
  final TransactionRepository repository;
  const AddProductsToTransaction(this.repository);

  Future<Result<TransactionEntity>> call({
    required String transactionId,
    required List<TransactionItemEntity> newItems,
  }) async {
    final existing = await repository.getById(transactionId);
    return existing.fold((transaction) async {
      final updated = transaction.copyWith(items: [...transaction.items, ...newItems]);
      final result = await repository.update(updated);
      return result.fold((_) => Success(updated), (f) => Failure(f));
    }, (f) async => Failure(f));
  }
}
