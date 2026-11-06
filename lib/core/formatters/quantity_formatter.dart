/// Formata quantidades no padrão brasileiro: inteiros sem casas decimais
/// ("3") e frações com vírgula ("1,5").
class QuantityFormatter {
  QuantityFormatter._();

  static String format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString().replaceAll('.', ',');
  }

  /// Lê o que o usuário digitou ("1,5" ou "1.5"); `null` se não for número.
  static double? parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
}
