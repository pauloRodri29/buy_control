import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class GetTransactionDetails {
  final TransactionRepository repository;
  const GetTransactionDetails(this.repository);

  Future<Result<TransactionEntity>> call(String id) {
    return repository.getById(id);
  }
}
