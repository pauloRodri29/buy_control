import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';
import 'package:buy_control/features/box_closures/domain/usecases/close_box.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closure_details.dart';
import 'package:buy_control/features/box_closures/domain/usecases/reopen_box_closure.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:buy_control/features/transactions/domain/usecases/update_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBoxRepository implements BoxRepository {
  final Map<String, BoxEntity> store = {};
  @override
  Future<Result<void>> create(BoxEntity box) async {
    store[box.id] = box;
    return const Success(null);
  }
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<BoxEntity>>> getAll({bool includeArchived = false, bool includeDeleted = false}) async =>
      Success(store.values.toList());
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
  final Map<String, TransactionEntity> store = {};
  @override
  Future<Result<void>> create(TransactionEntity transaction) async {
    store[transaction.id] = transaction;
    return const Success(null);
  }
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<TransactionEntity>>> getAll({String? boxId, bool includeDeleted = false}) async {
    final all = store.values.where((t) => includeDeleted || !t.isDeleted);
    return Success(boxId == null ? all.toList() : all.where((t) => t.boxId == boxId).toList());
  }
  @override
  Future<Result<TransactionEntity>> getById(String id) async {
    final t = store[id];
    if (t == null) return const Failure(NotFoundFailure());
    return Success(t);
  }
  @override
  Future<Result<void>> update(TransactionEntity transaction) async {
    store[transaction.id] = transaction;
    return const Success(null);
  }
}

TransactionEntity _openTransaction(String id, String boxId, double priceReais) {
  final now = DateTime.now();
  return TransactionEntity(
    id: id,
    boxId: boxId,
    occurredAt: now,
    items: [
      TransactionItemEntity(
        id: '$id-item',
        transactionId: id,
        nameSnapshot: 'Item',
        unitId: 'un',
        quantity: 1,
        unitPrice: Money.fromReais(priceReais),
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CloseBox', () {
    test('congela os lançamentos abertos num Fechamento e calcula o total', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final transactionRepository = FakeTransactionRepository();
      await transactionRepository.create(_openTransaction('t1', 'b1', 10));
      await transactionRepository.create(_openTransaction('t2', 'b1', 25));
      final closureRepository = _FakeBoxClosureRepository();

      final closeBox = CloseBox(
        boxRepository: boxRepository,
        transactionRepository: transactionRepository,
        closureRepository: closureRepository,
      );

      final result = await closeBox(boxId: 'b1');

      expect(result.isSuccess, isTrue);
      final closure = result.dataOrNull!;
      expect(closure.total.cents, 3500);
      expect(closure.transactionCount, 2);
      expect(closure.boxNameSnapshot, 'Mercado');

      final t1 = (await transactionRepository.getById('t1')).dataOrNull!;
      final t2 = (await transactionRepository.getById('t2')).dataOrNull!;
      expect(t1.closureId, closure.id);
      expect(t2.closureId, closure.id);
    });

    test('rejeita fechar uma Box sem lançamentos abertos', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final closeBox = CloseBox(
        boxRepository: boxRepository,
        transactionRepository: FakeTransactionRepository(),
        closureRepository: _FakeBoxClosureRepository(),
      );

      final result = await closeBox(boxId: 'b1');

      expect(result.isFailure, isTrue);
    });
  });

  group('Guarda de imutabilidade', () {
    test('UpdateTransaction rejeita editar um lançamento já fechado', () async {
      final transactionRepository = FakeTransactionRepository();
      final closed = _openTransaction('t1', 'b1', 10).copyWith(closureId: 'closure-1');
      await transactionRepository.create(closed);

      final result = await UpdateTransaction(transactionRepository)(closed);

      expect(result.isFailure, isTrue);
    });

    test('DeleteTransaction rejeita excluir um lançamento já fechado', () async {
      final transactionRepository = FakeTransactionRepository();
      final closed = _openTransaction('t1', 'b1', 10).copyWith(closureId: 'closure-1');
      await transactionRepository.create(closed);

      final result = await DeleteTransaction(transactionRepository)('t1');

      expect(result.isFailure, isTrue);
    });
  });

  group('ReopenBoxClosure', () {
    test('devolve os lançamentos ao estado aberto e remove o Fechamento', () async {
      final now = DateTime.now();
      final transactionRepository = FakeTransactionRepository();
      final closure = BoxClosureEntity(
        id: 'closure-1',
        boxId: 'b1',
        boxNameSnapshot: 'Mercado',
        closedAt: now,
        total: Money.fromReais(10),
        transactionCount: 1,
        itemCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      final closureRepository = _FakeBoxClosureRepository()..store[closure.id] = closure;
      await transactionRepository.create(_openTransaction('t1', 'b1', 10).copyWith(closureId: closure.id));

      final result = await ReopenBoxClosure(
        closureRepository: closureRepository,
        transactionRepository: transactionRepository,
      )(closure.id);

      expect(result.isSuccess, isTrue);
      final t1 = (await transactionRepository.getById('t1')).dataOrNull!;
      expect(t1.closureId, isNull);
      expect(closureRepository.store[closure.id]!.isDeleted, isTrue);
    });
  });

  group('GetBoxClosureDetails', () {
    test('retorna o fechamento junto dos lançamentos presos a ele', () async {
      final now = DateTime.now();
      final transactionRepository = FakeTransactionRepository();
      final closure = BoxClosureEntity(
        id: 'closure-1',
        boxId: 'b1',
        boxNameSnapshot: 'Mercado',
        closedAt: now,
        total: Money.fromReais(10),
        transactionCount: 1,
        itemCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      final closureRepository = _FakeBoxClosureRepository()..store[closure.id] = closure;
      await transactionRepository.create(_openTransaction('t1', 'b1', 10).copyWith(closureId: closure.id));
      await transactionRepository.create(_openTransaction('t2', 'b1', 99));

      final result = await GetBoxClosureDetails(
        closureRepository: closureRepository,
        transactionRepository: transactionRepository,
      )(closure.id);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.transactions.map((t) => t.id), ['t1']);
    });
  });
}

class _FakeBoxClosureRepository implements BoxClosureRepository {
  final Map<String, BoxClosureEntity> store = {};
  @override
  Future<Result<void>> create(BoxClosureEntity closure) async {
    store[closure.id] = closure;
    return const Success(null);
  }
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<BoxClosureEntity>>> getAll({String? boxId, bool includeDeleted = false}) async {
    final all = store.values.where((c) => includeDeleted || !c.isDeleted);
    return Success(boxId == null ? all.toList() : all.where((c) => c.boxId == boxId).toList());
  }
  @override
  Future<Result<BoxClosureEntity>> getById(String id) async {
    final c = store[id];
    if (c == null) return const Failure(NotFoundFailure());
    return Success(c);
  }
  @override
  Future<Result<void>> update(BoxClosureEntity closure) async {
    store[closure.id] = closure;
    return const Success(null);
  }
}
