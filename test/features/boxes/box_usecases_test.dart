import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/boxes/domain/usecases/create_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/delete_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_summary.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBoxRepository implements BoxRepository {
  final Map<String, BoxEntity> store = {};

  @override
  Future<Result<void>> create(BoxEntity box) async {
    store[box.id] = box;
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    store.remove(id);
    return const Success(null);
  }

  @override
  Future<Result<List<BoxEntity>>> getAll({bool includeArchived = false, bool includeDeleted = false}) async {
    return Success(store.values
        .where((b) => includeDeleted || !b.isDeleted)
        .where((b) => includeArchived || !b.isArchived)
        .toList());
  }

  @override
  Future<Result<BoxEntity>> getById(String id) async {
    final box = store[id];
    if (box == null) return const Failure(NotFoundFailure());
    return Success(box);
  }

  @override
  Future<Result<void>> update(BoxEntity box) async {
    store[box.id] = box;
    return const Success(null);
  }
}

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> transactions;
  FakeTransactionRepository(this.transactions);

  @override
  Future<Result<void>> create(TransactionEntity transaction) async => const Success(null);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<TransactionEntity>>> getAll({String? boxId, bool includeDeleted = false}) async {
    return Success(boxId == null ? transactions : transactions.where((t) => t.boxId == boxId).toList());
  }
  @override
  Future<Result<TransactionEntity>> getById(String id) async => Success(transactions.first);
  @override
  Future<Result<void>> update(TransactionEntity transaction) async => const Success(null);
}

void main() {
  group('CreateBox', () {
    test('cria box válida', () async {
      final repository = FakeBoxRepository();
      final usecase = CreateBox(repository);

      final result = await usecase(name: 'Mercado');

      expect(result.isSuccess, isTrue);
      expect(repository.store.length, 1);
      expect(result.dataOrNull!.hasDuplicateName, isFalse);
    });

    test('rejeita nome vazio', () async {
      final repository = FakeBoxRepository();
      final usecase = CreateBox(repository);

      final result = await usecase(name: '   ');

      expect(result.isFailure, isTrue);
      expect(repository.store, isEmpty);
    });

    test('sinaliza nome duplicado sem bloquear', () async {
      final repository = FakeBoxRepository();
      final usecase = CreateBox(repository);

      await usecase(name: 'Mercado');
      final result = await usecase(name: 'mercado ');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.hasDuplicateName, isTrue);
      expect(repository.store.length, 2);
    });
  });

  group('DeleteBox', () {
    test('exclusão é lógica (deletedAt setado, registro permanece)', () async {
      final repository = FakeBoxRepository();
      final now = DateTime.now();
      repository.store['b1'] = BoxEntity(id: 'b1', name: 'Casa', createdAt: now, updatedAt: now);

      final usecase = DeleteBox(repository);
      final result = await usecase('b1');

      expect(result.isSuccess, isTrue);
      expect(repository.store.containsKey('b1'), isTrue);
      expect(repository.store['b1']!.isDeleted, isTrue);
    });
  });

  group('GetBoxSummary', () {
    test('consolida total, quantidade de lançamentos e itens de uma box', () async {
      final boxRepository = FakeBoxRepository();
      final now = DateTime.now();
      boxRepository.store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);

      final item1 = TransactionItemEntity(
        id: 'i1',
        transactionId: 't1',
        nameSnapshot: 'Café',
        unitId: 'un',
        quantity: 2,
        unitPrice: Money.fromReais(10),
      );
      final item2 = TransactionItemEntity(
        id: 'i2',
        transactionId: 't2',
        nameSnapshot: 'Leite',
        unitId: 'un',
        quantity: 1,
        unitPrice: Money.fromReais(5),
      );
      final transactions = [
        TransactionEntity(id: 't1', boxId: 'b1', occurredAt: now, items: [item1], createdAt: now, updatedAt: now),
        TransactionEntity(id: 't2', boxId: 'b1', occurredAt: now, items: [item2], createdAt: now, updatedAt: now),
      ];

      final usecase = GetBoxSummary(
        boxRepository: boxRepository,
        transactionRepository: FakeTransactionRepository(transactions),
      );

      final result = await usecase('b1');

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;
      expect(summary.total.cents, 2500);
      expect(summary.transactionCount, 2);
      expect(summary.itemCount, 2);
    });
  });
}
