import 'package:buy_control/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('fromReais converte para centavos corretamente', () {
      expect(Money.fromReais(13.79).cents, 1379);
      expect(Money.fromReais(0.1).cents, 10);
    });

    test('toDouble converte de volta para reais', () {
      expect(const Money(1379).toDouble(), 13.79);
    });

    test('soma e subtração operam em centavos', () {
      final a = Money.fromReais(10.00);
      final b = Money.fromReais(3.50);
      expect((a + b).cents, 1350);
      expect((a - b).cents, 650);
    });

    test('multiplicação por quantidade (subtotal = qty * unitPrice)', () {
      final unitPrice = Money.fromReais(13.79);
      final subtotal = unitPrice * 3;
      expect(subtotal.cents, 4137);
    });

    test('comparação entre valores', () {
      expect(Money.fromReais(5) < Money.fromReais(10), isTrue);
      expect(Money.fromReais(10) >= Money.fromReais(10), isTrue);
    });

    test('isNegative e isZero', () {
      expect(const Money(-100).isNegative, isTrue);
      expect(Money.zero.isZero, isTrue);
    });

    test('igualdade por valor', () {
      expect(Money.fromReais(13.79), Money.fromReais(13.79));
    });
  });
}
