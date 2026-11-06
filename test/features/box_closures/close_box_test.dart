import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';
import 'package:buy_control/features/box_closures/domain/usecases/close_box.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closure_details.dart';
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

  /// Simula falha de gravação ao criar lançamentos (para testar rollback).
  bool failCreates = false;

  @override
  Future<Result<void>> create(TransactionEntity transaction) async {
    if (failCreates) return const Failure(CacheFailure());
    store[transaction.id] = transaction;
    return const Success(null);
  }
  @override
  Future<Result<void>> delete(String id) async {
    store.remove(id);
    return const Success(null);
  }
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

      final result = await closeBox(boxId: 'b1', referenceDate: DateTime(2026, 10, 31, 15, 30));

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

    test('guarda a data de referência sem horário, no Fechamento e nos lançamentos', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final transactionRepository = FakeTransactionRepository();
      await transactionRepository.create(_openTransaction('t1', 'b1', 10));

      final result = await CloseBox(
        boxRepository: boxRepository,
        transactionRepository: transactionRepository,
        closureRepository: _FakeBoxClosureRepository(),
      )(boxId: 'b1', referenceDate: DateTime(2026, 10, 31, 15, 30));

      expect(result.dataOrNull!.referenceDate, DateTime(2026, 10, 31));
      final t1 = (await transactionRepository.getById('t1')).dataOrNull!;
      expect(t1.closureReferenceDate, DateTime(2026, 10, 31));
      expect(t1.accountingDate, DateTime(2026, 10, 31));
    });

    test('mantém os mesmos produtos na Box como novo ciclo aberto', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final transactionRepository = FakeTransactionRepository();
      final original = _openTransaction('t1', 'b1', 10);
      await transactionRepository.create(original.copyWith(
        items: [original.items.first.copyWith(quantity: 3, discount: Money.fromReais(2))],
      ));

      await CloseBox(
        boxRepository: boxRepository,
        transactionRepository: transactionRepository,
        closureRepository: _FakeBoxClosureRepository(),
      )(boxId: 'b1', referenceDate: DateTime(2026, 10, 31));

      final all = (await transactionRepository.getAll(boxId: 'b1')).dataOrNull!;
      final open = all.where((t) => !t.isClosed).toList();
      expect(all, hasLength(2));
      expect(open, hasLength(1));

      final copy = open.single;
      expect(copy.id, isNot('t1'));
      expect(copy.items.single.id, isNot('t1-item'));
      expect(copy.items.single.transactionId, copy.id);
      expect(copy.items.single.quantity, 3);
      expect(copy.items.single.unitPrice, Money.fromReais(10));
      expect(copy.items.single.discount, Money.fromReais(2));
      expect(copy.total, Money.fromReais(28));
    });

    test('só copia para o próximo ciclo os lançamentos marcados para repetir', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final transactionRepository = FakeTransactionRepository();
      await transactionRepository.create(_openTransaction('t1', 'b1', 10).copyWith(description: 'Feira'));
      await transactionRepository.create(_openTransaction('t2', 'b1', 25).copyWith(carryOver: false));

      final result = await CloseBox(
        boxRepository: boxRepository,
        transactionRepository: transactionRepository,
        closureRepository: _FakeBoxClosureRepository(),
      )(boxId: 'b1', referenceDate: DateTime(2026, 10, 31));

      // O Fechamento registra os dois; só o marcado volta para a Box.
      expect(result.dataOrNull!.transactionCount, 2);
      final open = (await transactionRepository.getAll(boxId: 'b1')).dataOrNull!.where((t) => !t.isClosed).toList();
      expect(open, hasLength(1));
      expect(open.single.total, Money.fromReais(10));
      expect(open.single.description, 'Feira');
      expect(open.single.carryOver, isTrue);
    });

    test('com nada marcado para repetir, a Box fica vazia após o fechamento', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final transactionRepository = FakeTransactionRepository();
      await transactionRepository.create(_openTransaction('t1', 'b1', 10).copyWith(carryOver: false));

      final result = await CloseBox(
        boxRepository: boxRepository,
        transactionRepository: transactionRepository,
        closureRepository: _FakeBoxClosureRepository(),
      )(boxId: 'b1', referenceDate: DateTime(2026, 10, 31));

      expect(result.isSuccess, isTrue);
      final all = (await transactionRepository.getAll(boxId: 'b1')).dataOrNull!;
      expect(all.where((t) => !t.isClosed), isEmpty);
    });

    test('desfaz tudo se uma gravação falhar no meio do fechamento', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final transactionRepository = FakeTransactionRepository();
      await transactionRepository.create(_openTransaction('t1', 'b1', 10));
      await transactionRepository.create(_openTransaction('t2', 'b1', 25));
      transactionRepository.failCreates = true;
      final closureRepository = _FakeBoxClosureRepository();

      final result = await CloseBox(
        boxRepository: boxRepository,
        transactionRepository: transactionRepository,
        closureRepository: closureRepository,
      )(boxId: 'b1', referenceDate: DateTime(2026, 10, 31));

      expect(result.isFailure, isTrue);
      expect(closureRepository.store, isEmpty);
      final all = (await transactionRepository.getAll(boxId: 'b1')).dataOrNull!;
      expect(all.map((t) => t.id).toSet(), {'t1', 't2'});
      expect(all.every((t) => !t.isClosed), isTrue);
    });

    test('rejeita fechar uma Box sem lançamentos abertos', () async {
      final now = DateTime.now();
      final boxRepository = FakeBoxRepository()..store['b1'] = BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now);
      final closeBox = CloseBox(
        boxRepository: boxRepository,
        transactionRepository: FakeTransactionRepository(),
        closureRepository: _FakeBoxClosureRepository(),
      );

      final result = await closeBox(boxId: 'b1', referenceDate: DateTime(2026, 10, 31, 15, 30));

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


  group('GetBoxClosureDetails', () {
    test('retorna o fechamento junto dos lançamentos presos a ele', () async {
      final now = DateTime.now();
      final transactionRepository = FakeTransactionRepository();
      final closure = BoxClosureEntity(
        id: 'closure-1',
        boxId: 'b1',
        boxNameSnapshot: 'Mercado',
        referenceDate: DateTime(now.year, now.month, now.day),
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
  Future<Result<void>> delete(String id) async {
    store.remove(id);
    return const Success(null);
  }
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
