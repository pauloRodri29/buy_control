import 'package:buy_control/core/extensions/string_extensions.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class SearchTransactions {
  final TransactionRepository repository;
  const SearchTransactions(this.repository);

  Future<Result<List<TransactionEntity>>> call({
    String? boxId,
    required String query,
  }) async {
    final result = await repository.getAll(boxId: boxId);
    return result.fold((transactions) {
      final matches = transactions.where((transaction) {
        if ((transaction.title ?? '').containsSearchTerm(query)) return true;
        if ((transaction.notes ?? '').containsSearchTerm(query)) return true;
        return transaction.items.any((item) => item.nameSnapshot.containsSearchTerm(query));
      }).toList();
      return Success(matches);
    }, (f) => Failure(f));
  }
}
