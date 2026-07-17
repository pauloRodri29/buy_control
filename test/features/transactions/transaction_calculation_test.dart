import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionItemEntity', () {
    test('subtotal = quantidade * preço unitário', () {
      final item = TransactionItemEntity(
        id: '1',
        transactionId: 't1',
        nameSnapshot: 'Café',
        unitId: 'un',
        quantity: 3,
        unitPrice: Money.fromReais(13.79),
      );
      expect(item.subtotal.cents, 4137);
    });

    test('total = subtotal - desconto + acréscimo', () {
      final item = TransactionItemEntity(
        id: '1',
        transactionId: 't1',
        nameSnapshot: 'Café',
        unitId: 'un',
        quantity: 2,
        unitPrice: Money.fromReais(10),
        discount: Money.fromReais(2),
        additionalCost: Money.fromReais(1),
      );
      expect(item.subtotal.cents, 2000);
      expect(item.total.cents, 1900);
    });
  });

  group('TransactionEntity', () {
    test('total = soma dos itens - desconto geral + acréscimo geral', () {
      final now = DateTime.now();
      final items = [
        TransactionItemEntity(
          id: '1',
          transactionId: 't1',
          nameSnapshot: 'Café',
          unitId: 'un',
          quantity: 3,
          unitPrice: Money.fromReais(13.79),
        ),
        TransactionItemEntity(
          id: '2',
          transactionId: 't1',
          nameSnapshot: 'Leite',
          unitId: 'un',
          quantity: 2,
          unitPrice: Money.fromReais(5.5),
        ),
      ];
      final transaction = TransactionEntity(
        id: 't1',
        boxId: 'box1',
        occurredAt: now,
        items: items,
        discount: Money.fromReais(1),
        additionalCost: Money.fromReais(3),
        createdAt: now,
        updatedAt: now,
      );

      // 41.37 + 11.00 = 52.37 -1.00 +3.00 = 54.37
      expect(transaction.itemsTotal.cents, 5237);
      expect(transaction.total.cents, 5437);
      expect(transaction.itemCount, 2);
    });

    test('desconto maior que o total resulta em total negativo (deve ser rejeitado pelo caso de uso)', () {
      final now = DateTime.now();
      final item = TransactionItemEntity(
        id: '1',
        transactionId: 't1',
        nameSnapshot: 'Item',
        unitId: 'un',
        quantity: 1,
        unitPrice: Money.fromReais(10),
      );
      final transaction = TransactionEntity(
        id: 't1',
        boxId: 'box1',
        occurredAt: now,
        items: [item],
        discount: Money.fromReais(50),
        createdAt: now,
        updatedAt: now,
      );

      expect(transaction.total.isNegative, isTrue);
    });
  });
}
