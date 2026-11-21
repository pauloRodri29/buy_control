import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/discount_rule.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/save_purchase_items.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> saved = [];

  @override
  Future<Result<void>> create(TransactionEntity transaction) async {
    saved.add(transaction);
    return const Success(null);
  }

  @override
  Future<Result<void>> update(TransactionEntity transaction) async {
    final index = saved.indexWhere((t) => t.id == transaction.id);
    saved[index] = transaction;
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<List<TransactionEntity>>> getAll({String? boxId, bool includeDeleted = false}) async =>
      Success(saved.where((t) => boxId == null || t.boxId == boxId).toList());

  @override
  Future<Result<TransactionEntity>> getById(String id) async => Success(saved.firstWhere((t) => t.id == id));
}

TransactionItemEntity _item(
  String productId, {
  double quantity = 1,
  int priceCents = 500,
  DiscountRule? rule,
}) {
  return TransactionItemEntity(
    id: 'item-$productId-$quantity-$priceCents',
    transactionId: '',
    productId: productId,
    nameSnapshot: 'Produto $productId',
    unitId: 'un',
    quantity: quantity,
    unitPrice: Money(priceCents),
    discountRule: rule,
  ).withRecalculatedDiscount();
}

void main() {
  late _InMemoryTransactionRepository repository;
  late SavePurchaseItems save;

  Future<SavePurchaseResult> run(List<TransactionItemEntity> items) async {
    final result = await save(boxId: 'box', occurredAt: DateTime(2026, 11, 21), items: items);
    expect(result.isSuccess, isTrue, reason: result.failureOrNull?.message);
    return result.dataOrNull!;
  }

  setUp(() {
    repository = _InMemoryTransactionRepository();
    save = SavePurchaseItems(repository);
  });

  group('SavePurchaseItems', () {
    test('cada produto escolhido vira o seu próprio lançamento', () async {
      final result = await run([_item('a'), _item('b'), _item('c')]);

      expect(result.created, 3);
      expect(repository.saved.length, 3);
      expect(repository.saved.every((t) => t.items.length == 1), isTrue);
    });

    test('mesmo produto aberto com o mesmo preço soma a quantidade', () async {
      await run([_item('a', quantity: 2)]);
      final result = await run([_item('a', quantity: 3)]);

      expect(result.merged, 1);
      expect(repository.saved.length, 1);
      expect(repository.saved.single.items.single.quantity, 5);
    });

    test('mesmo produto com outro preço vira lançamento separado', () async {
      await run([_item('a', priceCents: 500)]);
      final result = await run([_item('a', priceCents: 450)]);

      expect(result.created, 1);
      expect(repository.saved.length, 2);
    });

    test('não soma em lançamento já fechado', () async {
      await run([_item('a')]);
      repository.saved[0] = repository.saved[0].copyWith(closureId: 'fechamento');

      await run([_item('a')]);

      expect(repository.saved.length, 2);
    });

    test('item sem cadastro (avulso) nunca é somado', () async {
      final withoutProduct = TransactionItemEntity(
        id: 'avulso',
        transactionId: '',
        nameSnapshot: 'Pão da padaria',
        unitId: 'un',
        quantity: 1,
        unitPrice: Money(300),
      );
      await run([withoutProduct]);
      await run([withoutProduct]);

      expect(repository.saved.length, 2);
    });

    test('promoção é recalculada sobre a quantidade somada', () async {
      const rule = DiscountRule.buyXPayY(take: 3, pay: 2);
      await run([_item('a', quantity: 2, rule: rule)]);
      expect(repository.saved.single.items.single.discount, Money.zero);

      await run([_item('a', quantity: 1, rule: rule)]);

      final item = repository.saved.single.items.single;
      expect(item.quantity, 3);
      expect(item.discount, Money(500));
    });
  });
}
