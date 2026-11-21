import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../reports/get_consolidated_report_test.dart'
    show FakeBoxRepository, FakeCategoryRepository, FakeProductRepository, FakeTransactionRepository;
import 'planning_usecases_test.dart' show FakePlanBoardRepository, FakePlanItemRepository, board, item;

void main() {
  group('Relatório com Planejamento', () {
    late FakePlanBoardRepository boards;
    late FakePlanItemRepository items;
    late GetConsolidatedReport usecase;

    setUp(() async {
      boards = FakePlanBoardRepository();
      items = FakePlanItemRepository();

      // Quadro de dezembro com meta de R$ 500.
      await boards.create(board('dez', goalCents: 50000, date: DateTime(2026, 12, 31)));
      await boards.create(board('jan', date: DateTime(2027, 1, 31)));

      // Comprado em novembro (R$ 100) e em dezembro (R$ 200); pendente R$ 300.
      await items.create(item('nov', boardId: 'dez', cents: 10000, purchased: true)
          .copyWith(purchasedAt: DateTime(2026, 11, 10)));
      await items.create(item('dez1', boardId: 'dez', cents: 20000, purchased: true)
          .copyWith(purchasedAt: DateTime(2026, 12, 15)));
      await items.create(item('dez2', boardId: 'dez', cents: 30000));
      await items.create(item('jan1', boardId: 'jan', cents: 99900));

      final now = DateTime(2026, 12, 1);
      final transactions = [
        TransactionEntity(
          id: 't1',
          boxId: 'box1',
          occurredAt: DateTime(2026, 12, 3),
          items: [
            TransactionItemEntity(
              id: 'i1',
              transactionId: 't1',
              nameSnapshot: 'Café',
              unitId: 'un',
              quantity: 1,
              unitPrice: const Money(5000),
            ),
          ],
          closureId: 'c1',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      usecase = GetConsolidatedReport(
        boxRepository: FakeBoxRepository([BoxEntity(id: 'box1', name: 'Mercado', createdAt: now, updatedAt: now)]),
        transactionRepository: FakeTransactionRepository(transactions),
        categoryRepository: FakeCategoryRepository([]),
        productRepository: FakeProductRepository([]),
        planBoardRepository: boards,
        planItemRepository: items,
      );
    });

    test('dezembro: só itens comprados no mês somam ao total, previsão separada', () async {
      final report = (await usecase(
        start: DateTime(2026, 12, 1),
        end: DateTime(2026, 12, 31, 23, 59, 59),
      ))
          .dataOrNull!;

      // R$ 50 da Box + R$ 200 comprados em dezembro.
      expect(report.total, const Money(25000));
      expect(report.boxesTotal, const Money(5000));
      expect(report.planning!.purchasedTotal, const Money(20000));
      expect(report.planning!.purchasedCount, 1);
      // Pendente do quadro com previsão em dezembro.
      expect(report.planning!.forecastPending, const Money(30000));
      expect(report.planning!.goalTotal, const Money(50000));
      // Planejado no quadro (comprados + pendentes) = 100 + 200 + 300.
      expect(report.planning!.plannedInBoards, const Money(60000));
      expect(report.planning!.boardsInPeriod, 1);
      expect(report.evolution.single.total, const Money(25000));
    });

    test('novembro: a compra entra no mês da data de compra', () async {
      final report = (await usecase(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30, 23, 59, 59),
      ))
          .dataOrNull!;

      expect(report.transactionCount, 0);
      expect(report.total, const Money(10000));
      expect(report.isEmpty, isFalse);
      // Nenhum quadro com previsão em novembro.
      expect(report.planning!.pendingCount, 0);
    });

    test('evolução mensal soma Boxes e Planejamento por mês', () async {
      final report = (await usecase()).dataOrNull!;
      final byMonth = {for (final p in report.evolution) DateTime(p.month.year, p.month.month): p.total};
      expect(byMonth[DateTime(2026, 11)], const Money(10000));
      expect(byMonth[DateTime(2026, 12)], const Money(25000));
    });

    test('valor pago substitui o estimado no relatório', () async {
      await items.update(items.store['dez1']!.copyWith(paidValue: const Money(25000)));
      final report = (await usecase(
        start: DateTime(2026, 12, 1),
        end: DateTime(2026, 12, 31, 23, 59, 59),
      ))
          .dataOrNull!;
      expect(report.planning!.purchasedTotal, const Money(25000));
    });

    test('filtro de Box deixa o Planejamento de fora', () async {
      final report = (await usecase(boxIds: ['box1'])).dataOrNull!;
      expect(report.planning, isNull);
      expect(report.total, const Money(5000));
    });
  });
}
