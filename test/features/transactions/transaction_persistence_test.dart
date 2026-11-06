import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/data/mappers/transaction_mapper.dart';
import 'package:buy_control/features/transactions/data/models/transaction_model.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Persistência do lançamento', () {
    final now = DateTime(2026, 11, 5, 10);

    test('descrição, "repetir no próximo ciclo" e tipo do item sobrevivem a salvar e ler', () {
      final transaction = TransactionEntity(
        id: 't1',
        boxId: 'b1',
        title: 'Feira',
        occurredAt: now,
        description: 'Frutas da semana',
        notes: 'Pagar no pix',
        carryOver: false,
        items: [
          TransactionItemEntity(
            id: 'i1',
            transactionId: 't1',
            nameSnapshot: 'Banana',
            productTypeId: 'type-hortifruti',
            unitId: 'un',
            quantity: 2,
            unitPrice: Money.fromReais(3),
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = TransactionMapper.toModel(transaction).toMap();
      final restored = TransactionMapper.toEntity(TransactionModel.fromMap(map));

      expect(restored.description, 'Frutas da semana');
      expect(restored.notes, 'Pagar no pix');
      expect(restored.carryOver, isFalse);
      expect(restored.items.single.productTypeId, 'type-hortifruti');
    });

    test('lançamentos gravados antes dos campos novos continuam repetindo no próximo ciclo', () {
      final restored = TransactionMapper.toEntity(TransactionModel.fromMap({
        'id': 't1',
        'boxId': 'b1',
        'occurredAt': now.toIso8601String(),
        'notes': 'Descrição — observação antigas',
        'items': const [],
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'synced',
        'version': 1,
      }));

      expect(restored.carryOver, isTrue);
      expect(restored.description, isNull);
      expect(restored.notes, 'Descrição — observação antigas');
    });

    test('copyWith com clearNotes apaga a observação', () {
      final transaction = TransactionEntity(
        id: 't1',
        boxId: 'b1',
        occurredAt: now,
        notes: 'antiga',
        createdAt: now,
        updatedAt: now,
      );

      expect(transaction.copyWith(clearNotes: true).notes, isNull);
      expect(transaction.copyWith().notes, 'antiga');
    });
  });

  group('QuantityFormatter', () {
    test('inteiros sem casas e frações com vírgula', () {
      expect(QuantityFormatter.format(3), '3');
      expect(QuantityFormatter.format(1.5), '1,5');
    });

    test('lê vírgula ou ponto e rejeita texto inválido', () {
      expect(QuantityFormatter.parse(' 1,5 '), 1.5);
      expect(QuantityFormatter.parse('2.25'), 2.25);
      expect(QuantityFormatter.parse('abc'), isNull);
    });
  });
}
