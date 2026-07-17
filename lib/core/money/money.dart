import 'package:intl/intl.dart';

/// Valor monetário representado em centavos para evitar erros de
/// arredondamento em ponto flutuante nos cálculos financeiros.
class Money implements Comparable<Money> {
  final int cents;

  const Money(this.cents);

  static const zero = Money(0);

  factory Money.fromReais(double reais) => Money((reais * 100).round());

  double toDouble() => cents / 100;

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator *(num factor) => Money((cents * factor).round());

  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  bool get isNegative => cents < 0;
  bool get isZero => cents == 0;

  String get formatted =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(toDouble());

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => formatted;
}
