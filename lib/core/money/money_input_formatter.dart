import 'package:flutter/services.dart';
import 'package:buy_control/core/money/money.dart';

/// Máscara monetária "da direita para a esquerda": os dígitos digitados
/// são sempre interpretados como centavos, então "1234" vira "R$ 12,34"
/// enquanto o usuário digita — evita o padrão comum de mostrar o valor
/// cru e só formatar depois de salvar.
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cents = digits.isEmpty ? 0 : int.parse(digits);
    final formatted = Money(cents).formatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Extrai o [Money] representado pelo texto já formatado por este
  /// formatter (ou por qualquer texto contendo apenas dígitos + separadores).
  static Money parse(String formattedText) {
    final digits = formattedText.replaceAll(RegExp(r'[^0-9]'), '');
    return Money(digits.isEmpty ? 0 : int.parse(digits));
  }
}
