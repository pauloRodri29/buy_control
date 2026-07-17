import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_charts.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBoxRepository implements BoxRepository {
  final List<BoxEntity> boxes;
  FakeBoxRepository(this.boxes);
  @override
  Future<Result<void>> create(BoxEntity box) async => const Success(null);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<BoxEntity>>> getAll({bool includeArchived = false, bool includeDeleted = false}) async =>
      Success(boxes);
  @override
  Future<Result<BoxEntity>> getById(String id) async => Success(boxes.first);
  @override
  Future<Result<void>> update(BoxEntity box) async => const Success(null);
}

class FakeCategoryRepository implements CategoryRepository {
  final List<CategoryEntity> categories;
  FakeCategoryRepository(this.categories);
  @override
  Future<Result<void>> create(CategoryEntity category) async => const Success(null);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<CategoryEntity>>> getAll({bool includeInactive = false}) async => Success(categories);
  @override
  Future<Result<CategoryEntity>> getById(String id) async => Success(categories.first);
  @override
  Future<Result<void>> update(CategoryEntity category) async => const Success(null);
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

TransactionEntity _transaction({
  required String boxId,
  required DateTime occurredAt,
  String? categoryId,
  required double price,
}) {
  final now = DateTime.now();
  return TransactionEntity(
    id: 'tx-$boxId-${occurredAt.toIso8601String()}-$price',
    boxId: boxId,
    occurredAt: occurredAt,
    items: [
      TransactionItemEntity(
        id: 'item-$boxId-${occurredAt.toIso8601String()}',
        transactionId: 'tx',
        nameSnapshot: 'Item',
        categoryId: categoryId,
        unitId: 'un',
        quantity: 1,
        unitPrice: Money.fromReais(price),
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetDashboardCharts', () {
    test('agrega evolução mensal, por categoria e por box dentro do período', () async {
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);

      final boxes = [
        BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now),
        BoxEntity(id: 'b2', name: 'Casa', createdAt: now, updatedAt: now),
      ];
      final categories = [
        CategoryEntity(id: 'c1', name: 'Alimentação', createdAt: now, updatedAt: now),
      ];
      final transactions = [
        _transaction(boxId: 'b1', occurredAt: thisMonthStart.add(const Duration(days: 2)), categoryId: 'c1', price: 50),
        _transaction(boxId: 'b2', occurredAt: thisMonthStart.add(const Duration(days: 5)), categoryId: 'c1', price: 30),
        // fora do período (mês anterior) não deve entrar no periodTotal
        _transaction(boxId: 'b1', occurredAt: DateTime(now.year, now.month - 1, 10), categoryId: 'c1', price: 999),
      ];

      final usecase = GetDashboardCharts(
        boxRepository: FakeBoxRepository(boxes),
        transactionRepository: FakeTransactionRepository(transactions),
        categoryRepository: FakeCategoryRepository(categories),
      );

      final periodStart = thisMonthStart;
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      final result = await usecase(periodStart: periodStart, periodEnd: periodEnd);

      expect(result.isSuccess, isTrue);
      final charts = result.dataOrNull!;
      expect(charts.periodTotal.cents, 8000);
      expect(charts.spendingByBox.length, 2);
      expect(charts.spendingByCategory.length, 1);
      expect(charts.spendingByCategory.first.name, 'Alimentação');
      expect(charts.monthlyEvolution.length, 6);
      expect(charts.isEmpty, isFalse);
    });

    test('sem transações no período resulta em isEmpty', () async {
      final now = DateTime.now();
      final usecase = GetDashboardCharts(
        boxRepository: FakeBoxRepository([]),
        transactionRepository: FakeTransactionRepository([]),
        categoryRepository: FakeCategoryRepository([]),
      );

      final result = await usecase(periodStart: now, periodEnd: now);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.isEmpty, isTrue);
    });
  });
}
