import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/planning/data/mappers/plan_mappers.dart';
import 'package:buy_control/features/planning/data/models/plan_board_model.dart';
import 'package:buy_control/features/planning/data/models/plan_item_model.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_progress.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_board_usecases.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_positions.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlanBoardRepository implements PlanBoardRepository {
  final Map<String, PlanBoardEntity> store = {};

  @override
  Future<Result<void>> create(PlanBoardEntity board) async {
    store[board.id] = board;
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    store.remove(id);
    return const Success(null);
  }

  @override
  Future<Result<List<PlanBoardEntity>>> getAll({bool includeArchived = false}) async {
    return Success(store.values.where((b) => includeArchived || !b.isArchived).toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate)));
  }

  @override
  Future<Result<PlanBoardEntity>> getById(String id) async {
    final board = store[id];
    return board == null ? const Failure(NotFoundFailure()) : Success(board);
  }

  @override
  Future<Result<void>> update(PlanBoardEntity board) => create(board);
}

class FakePlanItemRepository implements PlanItemRepository {
  final Map<String, PlanItemEntity> store = {};

  @override
  Future<Result<void>> create(PlanItemEntity item) async {
    store[item.id] = item;
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    store.remove(id);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAll(List<String> ids) async {
    ids.forEach(store.remove);
    return const Success(null);
  }

  @override
  Future<Result<List<PlanItemEntity>>> getAll() async {
    return Success(store.values.toList()..sort((a, b) => a.position.compareTo(b.position)));
  }

  @override
  Future<Result<void>> update(PlanItemEntity item) => create(item);

  @override
  Future<Result<void>> updateAll(List<PlanItemEntity> items) async {
    for (final i in items) {
      store[i.id] = i;
    }
    return const Success(null);
  }
}

PlanItemEntity item(String id, {String? boardId, double position = 0, int? cents, bool purchased = false}) {
  final now = DateTime(2026, 11, 1);
  return PlanItemEntity(
    id: id,
    boardId: boardId,
    title: id,
    estimatedValue: cents == null ? null : Money(cents),
    position: position,
    isPurchased: purchased,
    createdAt: now,
    updatedAt: now,
  );
}

PlanBoardEntity board(String id, {int? goalCents, DateTime? date}) {
  final now = DateTime(2026, 11, 1);
  return PlanBoardEntity(
    id: id,
    title: id,
    goal: goalCents == null ? null : Money(goalCents),
    targetDate: date ?? DateTime(2026, 12, 31),
    createdAt: now,
    updatedAt: now,
  );
}

List<String> columnIds(FakePlanItemRepository repo, String? boardId) =>
    PlanItemPositions.column(repo.store.values, boardId).map((i) => i.id).toList();

void main() {
  group('CreatePlanBoard', () {
    test('exige título', () async {
      final result = await CreatePlanBoard(FakePlanBoardRepository())(title: '  ', targetDate: DateTime(2026, 12));
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejeita meta negativa', () async {
      final result = await CreatePlanBoard(FakePlanBoardRepository())(
        title: 'Dezembro',
        goal: const Money(-100),
        targetDate: DateTime(2026, 12),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('meta zero vira "sem meta" e a data perde o horário', () async {
      final result = await CreatePlanBoard(FakePlanBoardRepository())(
        title: ' Fim de ano ',
        goal: Money.zero,
        targetDate: DateTime(2026, 12, 31, 18, 30),
      );
      final created = result.dataOrNull!;
      expect(created.title, 'Fim de ano');
      expect(created.goal, isNull);
      expect(created.targetDate, DateTime(2026, 12, 31));
    });
  });

  group('CreatePlanItem', () {
    test('adiciona ao final da coluna do quadro', () async {
      final repo = FakePlanItemRepository();
      await repo.create(item('a', boardId: 'b1', position: 0));
      await repo.create(item('b', boardId: 'b1', position: 5));
      await repo.create(item('x', boardId: 'b2', position: 50));

      final created = (await CreatePlanItem(repo)(boardId: 'b1', title: 'Novo')).dataOrNull!;
      expect(created.position, 6);
      expect(columnIds(repo, 'b1').last, created.id);
    });

    test('valor zero vira "sem valor"', () async {
      final created = (await CreatePlanItem(FakePlanItemRepository())(title: 'TV', estimatedValue: Money.zero))
          .dataOrNull!;
      expect(created.estimatedValue, isNull);
    });
  });

  group('MovePlanItem', () {
    late FakePlanItemRepository repo;

    setUp(() async {
      repo = FakePlanItemRepository();
      await repo.create(item('a', boardId: 'b1', position: 0));
      await repo.create(item('b', boardId: 'b1', position: 1));
      await repo.create(item('c', boardId: 'b1', position: 2));
      await repo.create(item('x'));
    });

    test('move para o final de outro quadro', () async {
      await MovePlanItem(repo)(repo.store['x']!, toBoardId: 'b1');
      expect(columnIds(repo, 'b1'), ['a', 'b', 'c', 'x']);
      expect(columnIds(repo, null), isEmpty);
    });

    test('insere antes de um item', () async {
      await MovePlanItem(repo)(repo.store['x']!, toBoardId: 'b1', beforeItemId: 'b');
      expect(columnIds(repo, 'b1'), ['a', 'x', 'b', 'c']);
    });

    test('insere no topo', () async {
      await MovePlanItem(repo)(repo.store['c']!, toBoardId: 'b1', beforeItemId: 'a');
      expect(columnIds(repo, 'b1'), ['c', 'a', 'b']);
    });

    test('volta para "Sem quadro"', () async {
      await MovePlanItem(repo)(repo.store['a']!, toBoardId: null);
      expect(columnIds(repo, null), ['x', 'a']);
      expect(repo.store['a']!.boardId, isNull);
    });

    test('renumera a coluna quando as posições se esgotam', () async {
      repo.store['b'] = repo.store['b']!.copyWith(position: 1e-7);
      repo.store['a'] = repo.store['a']!.copyWith(position: 0);
      await MovePlanItem(repo)(repo.store['x']!, toBoardId: 'b1', beforeItemId: 'b');
      expect(columnIds(repo, 'b1'), ['a', 'x', 'b', 'c']);
      expect(PlanItemPositions.column(repo.store.values, 'b1').map((i) => i.position), [0, 1, 2, 3]);
    });
  });

  group('UpdatePlanItem', () {
    test('ao trocar de quadro, vai para o final do destino', () async {
      final repo = FakePlanItemRepository();
      await repo.create(item('a', boardId: 'b1', position: 0));
      await repo.create(item('z', boardId: 'b2', position: 10));

      await UpdatePlanItem(repo)(repo.store['a']!.copyWith(boardId: 'b2'));
      expect(columnIds(repo, 'b2'), ['z', 'a']);
      expect(repo.store['a']!.position, 11);
    });
  });

  group('DeletePlanBoard', () {
    late FakePlanBoardRepository boards;
    late FakePlanItemRepository items;

    setUp(() async {
      boards = FakePlanBoardRepository();
      items = FakePlanItemRepository();
      await boards.create(board('b1'));
      await items.create(item('a', boardId: 'b1', position: 0));
      await items.create(item('b', boardId: 'b1', position: 1));
      await items.create(item('x', position: 3));
    });

    test('por padrão, os itens vão para "Sem quadro"', () async {
      await DeletePlanBoard(boardRepository: boards, itemRepository: items)('b1');
      expect(boards.store, isEmpty);
      expect(columnIds(items, null), ['x', 'a', 'b']);
    });

    test('com deleteItems, exclui os itens junto', () async {
      await DeletePlanBoard(boardRepository: boards, itemRepository: items)('b1', deleteItems: true);
      expect(items.store.keys, ['x']);
    });
  });

  group('TogglePlanItemPurchased', () {
    test('marca e desmarca com data de compra', () async {
      final repo = FakePlanItemRepository();
      await repo.create(item('a'));
      await TogglePlanItemPurchased(repo)(repo.store['a']!);
      expect(repo.store['a']!.isPurchased, isTrue);
      expect(repo.store['a']!.purchasedAt, isNotNull);

      await TogglePlanItemPurchased(repo)(repo.store['a']!);
      expect(repo.store['a']!.isPurchased, isFalse);
      expect(repo.store['a']!.purchasedAt, isNull);
    });
  });

  group('PlanBoardProgress', () {
    test('soma planejado e comprado, conta itens sem valor', () {
      final progress = PlanBoardProgress.of(board('b1', goalCents: 100000), [
        item('a', cents: 30000, purchased: true),
        item('b', cents: 50000),
        item('c'),
      ]);
      expect(progress.planned, const Money(80000));
      expect(progress.purchased, const Money(30000));
      expect(progress.remaining, const Money(20000));
      expect(progress.goalRatio, closeTo(0.8, 1e-9));
      expect(progress.isOverGoal, isFalse);
      expect(progress.purchasedCount, 1);
      expect(progress.itemsWithoutValue, 1);
    });

    test('detecta meta estourada', () {
      final progress = PlanBoardProgress.of(board('b1', goalCents: 10000), [item('a', cents: 15000)]);
      expect(progress.isOverGoal, isTrue);
      expect(progress.remaining, const Money(-5000));
    });

    test('quadro sem meta', () {
      final progress = PlanBoardProgress.of(board('b1'), [item('a', cents: 15000)]);
      expect(progress.hasGoal, isFalse);
      expect(progress.remaining, isNull);
      expect(progress.isOverGoal, isFalse);
    });
  });

  group('Mappers', () {
    test('quadro sobrevive à ida e volta Map -> Entity -> Map', () {
      final original = board('b1', goalCents: 123456, date: DateTime(2027, 1, 31));
      final map = PlanBoardMapper.toModel(original).toMap();
      final back = PlanBoardMapper.toEntity(PlanBoardModel.fromMap(map));
      expect(back.goal, const Money(123456));
      expect(back.targetDate, DateTime(2027, 1, 31));
      expect(back.title, 'b1');
    });

    test('item sem valor e sem quadro sobrevive à ida e volta', () {
      final original = item('a', position: 2.5);
      final map = PlanItemMapper.toModel(original).toMap();
      final back = PlanItemMapper.toEntity(PlanItemModel.fromMap(map));
      expect(back.boardId, isNull);
      expect(back.estimatedValue, isNull);
      expect(back.position, 2.5);
    });
  });

  group('FinishPlanBoard', () {
    late FakePlanBoardRepository boards;
    late FakePlanItemRepository items;
    late FinishPlanBoard finish;

    setUp(() async {
      boards = FakePlanBoardRepository();
      items = FakePlanItemRepository();
      finish = FinishPlanBoard(boardRepository: boards, itemRepository: items);
      await boards.create(board('b1'));
      await boards.create(board('b2'));
      await items.create(item('bought', boardId: 'b1', purchased: true).copyWith(purchasedAt: DateTime(2026, 10, 5)));
      await items.create(item('a', boardId: 'b1', position: 1, cents: 2000));
      await items.create(item('b', boardId: 'b1', position: 2));
      await items.create(item('z', boardId: 'b2', position: 0));
    });

    test('exige destino para cada item não comprado', () async {
      final result = await finish(boards.store['b1']!, destinations: {
        'a': const PendingItemDestination.board('b2'),
      });
      expect(result.isFailure, isTrue);
      expect(boards.store['b1']!.isFinished, isFalse);
      expect(items.store['a']!.boardId, 'b1');
    });

    test('move para outro quadro ou manda para Pendências, e finaliza', () async {
      final now = DateTime(2026, 12, 20);
      final result = await finish(
        boards.store['b1']!,
        destinations: {
          'a': const PendingItemDestination.board('b2'),
          'b': const PendingItemDestination.pending('Sem estoque'),
        },
        paidValues: {'bought': const Money(1500)},
        now: now,
      );

      expect(result.isSuccess, isTrue);
      expect(boards.store['b1']!.closedAt, now);
      // Vai para o final do outro quadro, ainda a comprar.
      expect(columnIds(items, 'b2'), ['z', 'a']);
      expect(items.store['a']!.isPurchased, isFalse);
      // Pendência: fora do kanban, com motivo e quadro de origem.
      expect(items.store['b']!.isPending, isTrue);
      expect(items.store['b']!.notPurchasedReason, 'Sem estoque');
      expect(items.store['b']!.boardId, 'b1');
      expect(columnIds(items, 'b1'), ['bought']);
      // Valor pago registrado; data da compra preservada.
      expect(items.store['bought']!.paidValue, const Money(1500));
      expect(items.store['bought']!.purchasedAt, DateTime(2026, 10, 5));
    });

    test('Pendência exige motivo e o destino precisa ser um quadro aberto', () async {
      final blank = await finish(boards.store['b1']!, destinations: {
        'a': const PendingItemDestination.pending('  '),
        'b': const PendingItemDestination.pending('x'),
      });
      expect(blank.isFailure, isTrue);

      await boards.update(boards.store['b2']!.copyWith(closedAt: DateTime(2026, 12, 1)));
      final closedTarget = await finish(boards.store['b1']!, destinations: {
        'a': const PendingItemDestination.board('b2'),
        'b': const PendingItemDestination.pending('x'),
      });
      expect(closedTarget.isFailure, isTrue);
    });

    test('cancelar marca cancelledAt; quadro no histórico não finaliza de novo', () async {
      final now = DateTime(2026, 12, 20);
      final result = await finish(
        boards.store['b2']!,
        ending: PlanBoardEnding.cancel,
        destinations: {'z': const PendingItemDestination.pending('Desisti')},
        now: now,
      );
      expect(result.isSuccess, isTrue);
      expect(boards.store['b2']!.cancelledAt, now);
      expect(boards.store['b2']!.isClosed, isFalse);
      expect(boards.store['b2']!.isFinished, isTrue);

      final again = await finish(boards.store['b2']!);
      expect(again.isFailure, isTrue);
    });
  });

  group('Pendências e Histórico', () {
    test('enviar para um quadro tira o motivo e coloca no final, a comprar', () async {
      final items = FakePlanItemRepository();
      await items.create(item('x', boardId: 'b2', position: 0));
      final pending = item('p', boardId: 'b1').copyWith(notPurchasedReason: 'Preço alto');
      await items.create(pending);

      await SendPendingItemToBoard(items)(pending, boardId: 'b2');

      expect(items.store['p']!.isPending, isFalse);
      expect(columnIds(items, 'b2'), ['x', 'p']);
    });

    test('excluir um quadro do Histórico apaga as compras e mantém as Pendências', () async {
      final boards = FakePlanBoardRepository();
      final items = FakePlanItemRepository();
      await boards.create(board('b1').copyWith(closedAt: DateTime(2026, 12, 1)));
      await items.create(item('bought', boardId: 'b1', purchased: true));
      await items.create(item('p', boardId: 'b1').copyWith(notPurchasedReason: 'Sem estoque'));

      await DeletePlanBoard(boardRepository: boards, itemRepository: items)('b1');

      expect(boards.store, isEmpty);
      expect(items.store.keys, ['p']);
      expect(items.store['p']!.isPending, isTrue);
      // Continua fora do "Sem quadro".
      expect(columnIds(items, null), isEmpty);
    });

    test('criar a partir de modelo copia os itens desmarcados', () async {
      final boards = FakePlanBoardRepository();
      final items = FakePlanItemRepository();
      await boards.create(board('b1').copyWith(closedAt: DateTime(2026, 12, 1)));
      await items.create(item('a', boardId: 'b1', purchased: true, cents: 1000).copyWith(paidValue: const Money(1200)));
      await items.create(item('p', boardId: 'b1', position: 1).copyWith(notPurchasedReason: 'Sem estoque'));

      final result = await CreatePlanBoardFromTemplate(createBoard: CreatePlanBoard(boards), itemRepository: items)(
        boards.store['b1']!,
        title: 'Natal 2027',
        targetDate: DateTime(2027, 12, 24),
      );

      final created = result.dataOrNull!;
      final copies = PlanItemPositions.column(items.store.values, created.id);
      expect(copies.map((i) => i.title), ['a', 'p']);
      expect(copies.every((i) => !i.isPurchased && !i.isPending && i.paidValue == null), isTrue);
      // O valor de referência é o último pago.
      expect(copies.first.estimatedValue, const Money(1200));
      // O original fica intacto.
      expect(items.store['a']!.isPurchased, isTrue);
    });

    test('item com motivo e valor pago sobrevive à ida e volta no mapper', () {
      final original = item('a', boardId: 'b1', cents: 100)
          .copyWith(paidValue: const Money(150), notPurchasedReason: 'Sem estoque');
      final back = PlanItemMapper.toEntity(PlanItemModel.fromMap(PlanItemMapper.toModel(original).toMap()));
      expect(back.paidValue, const Money(150));
      expect(back.notPurchasedReason, 'Sem estoque');

      final cancelled = board('b1').copyWith(cancelledAt: DateTime(2026, 12, 2));
      final boardBack = PlanBoardMapper.toEntity(PlanBoardModel.fromMap(PlanBoardMapper.toModel(cancelled).toMap()));
      expect(boardBack.cancelledAt, DateTime(2026, 12, 2));
    });
  });
}
