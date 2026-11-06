import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarcodeParser', () {
    test('aceita EAN-13, EAN-8 e UPC-A com dígito verificador correto', () {
      expect(BarcodeParser.parse('4006381333931')?.kind, ScannedCodeKind.product);
      expect(BarcodeParser.parse('73513537')?.kind, ScannedCodeKind.product);
      expect(BarcodeParser.parse('036000291452')?.kind, ScannedCodeKind.product);
    });

    test('rejeita dígito verificador errado e tamanhos inválidos', () {
      expect(BarcodeParser.parse('4006381333932'), isNull);
      expect(BarcodeParser.parse('12345'), isNull);
      expect(BarcodeParser.parse(''), isNull);
    });

    test('ignora espaços e traços vindos do leitor', () {
      final code = BarcodeParser.parse(' 4006381-333931 ');
      expect(code?.digits, '4006381333931');
      expect(code?.lookupKey, '4006381333931');
    });

    test('etiqueta de balança separa a parte fixa do valor', () {
      final code = BarcodeParser.parse('2001234012348')!;
      expect(code.kind, ScannedCodeKind.scaleLabel);
      expect(code.lookupKey, '2001234');
      expect(code.scaleValue, 1234); // R$ 12,34 ou 1,234 kg
    });

    test('duas etiquetas do mesmo produto com valores diferentes têm a mesma chave', () {
      // 2001234 + 05678 + dígito verificador
      final a = BarcodeParser.parse('2001234012348')!;
      final b = BarcodeParser.parse('2001234056786')!;
      expect(b.scaleValue, 5678);
      expect(a.lookupKey, b.lookupKey);
    });

    test('storageKey guarda só a parte fixa de etiquetas e os dígitos de produtos', () {
      expect(BarcodeParser.storageKey('2001234012348'), '2001234');
      expect(BarcodeParser.storageKey('4006381333931'), '4006381333931');
      expect(BarcodeParser.storageKey('2001234'), '2001234');
      expect(BarcodeParser.storageKey(' 789 100-0 '), '7891000');
      expect(BarcodeParser.storageKey(' ABC-1 '), 'ABC-1');
      expect(BarcodeParser.storageKey(' ABC '), 'ABC');
    });
  });
}
