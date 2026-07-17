import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/create_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> saved = [];

  @override
  Future<Result<void>> create(TransactionEntity transaction) async {
    saved.add(transaction);
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<List<TransactionEntity>>> getAll({String? boxId, bool includeDeleted = false}) async {
    return Success(saved);
  }

  @override
  Future<Result<TransactionEntity>> getById(String id) async {
    return Success(saved.firstWhere((t) => t.id == id));
  }

  @override
  Future<Result<void>> update(TransactionEntity transaction) async => const Success(null);
}

void main() {
  group('CreateTransaction', () {
    test('cria lançamento válido com itens', () async {
      final repository = FakeTransactionRepository();
      final usecase = CreateTransaction(repository);

      final result = await usecase(
        boxId: 'box1',
        occurredAt: DateTime.now(),
        items: [
          TransactionItemEntity(
            id: '1',
            transactionId: 'tmp',
            nameSnapshot: 'Arroz',
            unitId: 'un',
            quantity: 2,
            unitPrice: Money.fromReais(20),
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(repository.saved.length, 1);
      expect(repository.saved.first.total.cents, 4000);
    });

    test('rejeita lançamento sem itens', () async {
      final repository = FakeTransactionRepository();
      final usecase = CreateTransaction(repository);

      final result = await usecase(boxId: 'box1', occurredAt: DateTime.now(), items: []);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.saved, isEmpty);
    });

    test('rejeita quando desconto torna o total negativo', () async {
      final repository = FakeTransactionRepository();
      final usecase = CreateTransaction(repository);

      final result = await usecase(
        boxId: 'box1',
        occurredAt: DateTime.now(),
        discount: Money.fromReais(100),
        items: [
          TransactionItemEntity(
            id: '1',
            transactionId: 'tmp',
            nameSnapshot: 'Item barato',
            unitId: 'un',
            quantity: 1,
            unitPrice: Money.fromReais(5),
          ),
        ],
      );

      expect(result.isFailure, isTrue);
      expect(repository.saved, isEmpty);
    });
  });
}
