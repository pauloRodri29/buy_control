import 'package:number_formatter2/number_formatter2.dart';

String formatPrice(double price) {
  // 1. Formata com decimal americano: 50,000.00
  String formatted = NumberFormatter.format(price, decimalPlaces: 2);

  // 2. Achar o último ponto (decimal)
  int lastDot = formatted.lastIndexOf('.');

  String integerUS = formatted.substring(0, lastDot);  // "50,000"
  String decimal = formatted.substring(lastDot + 1);   // "00"

  // 3. Remover vírgulas (separador US)
  String integerClean = integerUS.replaceAll(',', ''); // vira "50000"

  // 4. Reaplicar separador brasileiro de milhar
  String integerBR = _addThousandSeparator(integerClean);

  // 5. Unir com vírgula decimal
  return "R\$ $integerBR,$decimal";
}

// Função auxiliar para inserir pontos a cada 3 dígitos
String _addThousandSeparator(String number) {
  final buffer = StringBuffer();
  int count = 0;

  for (int i = number.length - 1; i >= 0; i--) {
    buffer.write(number[i]);
    count++;
    if (count == 3 && i != 0) {
      buffer.write('.');
      count = 0;
    }
  }

  return buffer.toString().split('').reversed.join();
}
