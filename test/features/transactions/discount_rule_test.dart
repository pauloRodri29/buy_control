import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/data/mappers/transaction_item_mapper.dart';
import 'package:buy_control/features/transactions/data/models/transaction_item_model.dart';
import 'package:buy_control/features/transactions/domain/entities/discount_rule.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Money _discount(DiscountRule rule, double quantity, double unitPrice) =>
    rule.calculate(itemQuantity: quantity, unitPrice: Money.fromReais(unitPrice));

void main() {
  group('DiscountRule.calculate', () {
    test('valor fixo abate o valor informado, limitado ao subtotal', () {
      final rule = DiscountRule.fixed(Money.fromReais(2));
      expect(_discount(rule, 3, 5), Money.fromReais(2));
      expect(_discount(DiscountRule.fixed(Money.fromReais(50)), 1, 5), Money.fromReais(5));
    });

    test('percentual incide sobre o subtotal', () {
      expect(_discount(const DiscountRule.percent(10), 2, 7.5), Money.fromReais(1.5));
    });

    test('leve 4 por R\$ 10: grupos completos saem pelo preço do pacote', () {
      final rule = DiscountRule.bundlePrice(quantity: 4, price: Money.fromReais(10));
      // 4 × 3,49 = 13,96 → paga 10,00
      expect(_discount(rule, 4, 3.49), Money.fromReais(3.96));
      // 6 un.: 1 grupo (10,00) + 2 × 3,49 = 16,98; subtotal 20,94
      expect(_discount(rule, 6, 3.49), Money.fromReais(3.96));
      // 8 un.: 2 grupos
      expect(_discount(rule, 8, 3.49), Money.fromReais(7.92));
      // 3 un.: não completa o grupo
      expect(_discount(rule, 3, 3.49), Money.zero);
    });

    test('leve 3 pague 2: a cada grupo completo uma unidade sai de graça', () {
      const rule = DiscountRule.buyXPayY(take: 3, pay: 2);
      expect(_discount(rule, 3, 4), Money.fromReais(4));
      expect(_discount(rule, 7, 4), Money.fromReais(8));
      expect(_discount(rule, 2, 4), Money.zero);
    });

    test('preço de atacado só vale a partir da quantidade mínima', () {
      final rule = DiscountRule.wholesale(minQuantity: 6, unitPrice: Money.fromReais(3));
      expect(_discount(rule, 5, 3.5), Money.zero);
      expect(_discount(rule, 6, 3.5), Money.fromReais(3));
    });

    test('parâmetros inválidos ou promoção pior que o preço normal não geram desconto', () {
      expect(_discount(DiscountRule.bundlePrice(quantity: 0, price: Money.fromReais(1)), 4, 3), Money.zero);
      expect(_discount(const DiscountRule.buyXPayY(take: 2, pay: 2), 4, 3), Money.zero);
      expect(_discount(DiscountRule.bundlePrice(quantity: 2, price: Money.fromReais(20)), 2, 3), Money.zero);
      expect(_discount(DiscountRule.wholesale(minQuantity: 2, unitPrice: Money.fromReais(9)), 2, 3), Money.zero);
    });
  });

  group('TransactionItemEntity com promoção', () {
    test('withRecalculatedDiscount acompanha mudanças de quantidade', () {
      final item = TransactionItemEntity(
        id: 'i1',
        transactionId: 't1',
        nameSnapshot: 'Leite',
        unitId: 'un',
        quantity: 3,
        unitPrice: Money.fromReais(4),
        discountRule: const DiscountRule.buyXPayY(take: 3, pay: 2),
      ).withRecalculatedDiscount();

      expect(item.total, Money.fromReais(8));
      final six = item.copyWith(quantity: 6).withRecalculatedDiscount();
      expect(six.total, Money.fromReais(16));
    });

    test('regra é preservada ao salvar e ler do armazenamento', () {
      final item = TransactionItemEntity(
        id: 'i1',
        transactionId: 't1',
        nameSnapshot: 'Arroz',
        unitId: 'un',
        quantity: 4,
        unitPrice: Money.fromReais(3.49),
        discountRule: DiscountRule.bundlePrice(quantity: 4, price: Money.fromReais(10)),
      ).withRecalculatedDiscount();

      final map = TransactionItemMapper.toModel(item).toMap();
      final restored = TransactionItemMapper.toEntity(TransactionItemModel.fromMap(map));

      expect(restored.discountRule, item.discountRule);
      expect(restored.discount, Money.fromReais(3.96));
    });

    test('itens antigos sem regra continuam com o desconto gravado', () {
      final restored = TransactionItemMapper.toEntity(TransactionItemModel.fromMap({
        'id': 'i1',
        'transactionId': 't1',
        'nameSnapshot': 'Café',
        'unitId': 'un',
        'quantity': 1,
        'unitPriceCents': 1000,
        'discountCents': 150,
      }));
      expect(restored.discountRule, isNull);
      expect(restored.discount, const Money(150));
    });
  });
}
