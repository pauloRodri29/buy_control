import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';

abstract interface class TransactionRepository {
  Future<Result<List<TransactionEntity>>> getAll({String? boxId, bool includeDeleted = false});
  Future<Result<TransactionEntity>> getById(String id);
  Future<Result<void>> create(TransactionEntity transaction);
  Future<Result<void>> update(TransactionEntity transaction);
  Future<Result<void>> delete(String id);
}
