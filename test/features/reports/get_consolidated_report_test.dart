import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
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

class FakeProductRepository implements ProductRepository {
  final List<ProductEntity> products;
  FakeProductRepository(this.products);
  @override
  Future<Result<void>> create(ProductEntity product) async => const Success(null);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<ProductEntity>>> getAll({bool includeInactive = false}) async => Success(products);
  @override
  Future<Result<ProductEntity>> getById(String id) async => Success(products.first);
  @override
  Future<Result<void>> update(ProductEntity product) async => const Success(null);
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
  group('GetConsolidatedReport', () {
    test('consolida total, médias e destaques entre múltiplas Boxes', () async {
      final now = DateTime.now();
      final boxes = [
        BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now),
        BoxEntity(id: 'b2', name: 'Mercado Livre', createdAt: now, updatedAt: now),
      ];
      final categories = [CategoryEntity(id: 'c1', name: 'Alimentação', createdAt: now, updatedAt: now)];
      final products = [
        ProductEntity(
          id: 'p1',
          name: 'Café',
          categoryId: 'c1',
          productTypeId: 't1',
          defaultUnitId: 'un',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final item1 = TransactionItemEntity(
        id: 'i1',
        transactionId: 't1',
        productId: 'p1',
        nameSnapshot: 'Café',
        categoryId: 'c1',
        unitId: 'un',
        quantity: 3,
        unitPrice: Money.fromReais(10),
      );
      final item2 = TransactionItemEntity(
        id: 'i2',
        transactionId: 't2',
        productId: 'p1',
        nameSnapshot: 'Café',
        categoryId: 'c1',
        unitId: 'un',
        quantity: 1,
        unitPrice: Money.fromReais(10),
      );
      final transactions = [
        TransactionEntity(id: 't1', boxId: 'b1', occurredAt: now, items: [item1], createdAt: now, updatedAt: now),
        TransactionEntity(id: 't2', boxId: 'b2', occurredAt: now, items: [item2], createdAt: now, updatedAt: now),
      ];

      final usecase = GetConsolidatedReport(
        boxRepository: FakeBoxRepository(boxes),
        transactionRepository: FakeTransactionRepository(transactions),
        categoryRepository: FakeCategoryRepository(categories),
        productRepository: FakeProductRepository(products),
      );

      final result = await usecase();

      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.total.cents, 4000);
      expect(report.transactionCount, 2);
      expect(report.itemCount, 2);
      expect(report.averagePerBox.cents, 2000);
      expect(report.topBox!.id, 'b1');
      expect(report.mostPurchasedProduct!.quantity, 4);
      expect(report.highestImpactProduct!.total.cents, 4000);
      expect(report.isEmpty, isFalse);
    });

    test('filtra por Box específica', () async {
      final now = DateTime.now();
      final boxes = [BoxEntity(id: 'b1', name: 'Mercado', createdAt: now, updatedAt: now)];
      final item = TransactionItemEntity(
        id: 'i1',
        transactionId: 't1',
        nameSnapshot: 'Item',
        unitId: 'un',
        quantity: 1,
        unitPrice: Money.fromReais(20),
      );
      final transactions = [
        TransactionEntity(id: 't1', boxId: 'b1', occurredAt: now, items: [item], createdAt: now, updatedAt: now),
        TransactionEntity(id: 't2', boxId: 'b2', occurredAt: now, items: [item], createdAt: now, updatedAt: now),
      ];

      final usecase = GetConsolidatedReport(
        boxRepository: FakeBoxRepository(boxes),
        transactionRepository: FakeTransactionRepository(transactions),
        categoryRepository: FakeCategoryRepository([]),
        productRepository: FakeProductRepository([]),
      );

      final result = await usecase(boxIds: ['b1']);

      expect(result.dataOrNull!.transactionCount, 1);
      expect(result.dataOrNull!.total.cents, 2000);
    });

    test('sem lançamentos correspondentes resulta em isEmpty', () async {
      final usecase = GetConsolidatedReport(
        boxRepository: FakeBoxRepository([]),
        transactionRepository: FakeTransactionRepository([]),
        categoryRepository: FakeCategoryRepository([]),
        productRepository: FakeProductRepository([]),
      );

      final result = await usecase();

      expect(result.dataOrNull!.isEmpty, isTrue);
    });
  });
}
