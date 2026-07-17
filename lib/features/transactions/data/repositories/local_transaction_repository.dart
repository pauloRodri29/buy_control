import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/mappers/transaction_mapper.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class LocalTransactionRepository implements TransactionRepository {
  final TransactionHiveDataSource localDataSource;
  const LocalTransactionRepository({required this.localDataSource});

  @override
  Future<Result<List<TransactionEntity>>> getAll({
    String? boxId,
    bool includeDeleted = false,
  }) async {
    try {
      final models = await localDataSource.getAll();
      final entities = models
          .map(TransactionMapper.toEntity)
          .where((t) => includeDeleted || !t.isDeleted)
          .where((t) => boxId == null || t.boxId == boxId)
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return Success(entities);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<TransactionEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(TransactionMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(TransactionEntity transaction) async {
    try {
      await localDataSource.put(TransactionMapper.toModel(transaction));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> update(TransactionEntity transaction) async {
    try {
      await localDataSource.put(TransactionMapper.toModel(transaction));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await localDataSource.delete(id);
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }
}
