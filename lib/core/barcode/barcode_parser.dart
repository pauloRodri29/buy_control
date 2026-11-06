/// O que um código lido representa.
enum ScannedCodeKind {
  /// Código de produto (EAN-13, EAN-8, UPC-A, GTIN-14): o mesmo em qualquer
  /// loja — identifica o produto diretamente.
  product,

  /// Etiqueta impressa pela balança da loja (carne, frios, pão, hortifruti):
  /// EAN-13 começando com "2", com o código interno da loja e um valor
  /// variável (preço ou peso) embutidos.
  scaleLabel,
}

/// Resultado da leitura de um código de barras.
class ScannedCode {
  final ScannedCodeKind kind;

  /// Só os dígitos do código lido.
  final String digits;

  /// Chave usada para achar o produto cadastrado. Para código de produto
  /// é o próprio código; para etiqueta de balança é a parte fixa
  /// ("2" + código interno), sem o valor — assim a mesma chave reconhece
  /// o produto em qualquer etiqueta, com qualquer peso/preço.
  final String lookupKey;

  /// Valor embutido na etiqueta de balança (5 dígitos): centavos, se a
  /// balança imprime preço; gramas, se imprime peso. `null` para produtos.
  final int? scaleValue;

  const ScannedCode({
    required this.kind,
    required this.digits,
    required this.lookupKey,
    this.scaleValue,
  });

  bool get isScaleLabel => kind == ScannedCodeKind.scaleLabel;
}

/// Interpreta códigos de barras lidos pela câmera (ou digitados).
///
/// Layout assumido para etiquetas de balança (EAN-13 de circulação
/// restrita, prefixo "2"), o mais comum nas balanças usadas no Brasil:
///
/// ```
/// 2 CCCCCC VVVVV D
/// │ │      │     └ dígito verificador
/// │ │      └ valor: preço em centavos ou peso em gramas
/// │ └ código interno do produto na loja (6 dígitos, pode ter zeros)
/// └ prefixo de etiqueta de balança
/// ```
///
/// Algumas balanças usam outra divisão; se for o caso, ajuste
/// [scaleKeyLength] e [scaleValueLength] — o valor sempre pode ser
/// corrigido pelo usuário antes de lançar.
class BarcodeParser {
  BarcodeParser._();

  /// Tamanho da parte fixa da etiqueta de balança, incluindo o "2".
  static const scaleKeyLength = 7;

  /// Tamanho do campo de valor da etiqueta de balança.
  static const scaleValueLength = 5;

  static final _nonDigits = RegExp(r'\D');

  /// Mantém só os dígitos (leitores às vezes incluem espaços/traços).
  static String normalize(String raw) => raw.replaceAll(_nonDigits, '');

  /// Confere o dígito verificador GTIN (EAN-8, UPC-A, EAN-13, GTIN-14).
  static bool hasValidCheckDigit(String digits) {
    if (![8, 12, 13, 14].contains(digits.length)) return false;
    var sum = 0;
    // Da direita para a esquerda, sem o dígito verificador: pesos 3,1,3,1...
    for (var i = digits.length - 2, weight = 3; i >= 0; i--, weight = weight == 3 ? 1 : 3) {
      sum += int.parse(digits[i]) * weight;
    }
    final expected = (10 - sum % 10) % 10;
    return expected == int.parse(digits[digits.length - 1]);
  }

  /// `null` quando o texto não é um código de barras de produto válido.
  static ScannedCode? parse(String raw) {
    final digits = normalize(raw);
    if (!hasValidCheckDigit(digits)) return null;

    if (digits.length == 13 && digits.startsWith('2')) {
      final valueStart = scaleKeyLength;
      return ScannedCode(
        kind: ScannedCodeKind.scaleLabel,
        digits: digits,
        lookupKey: digits.substring(0, scaleKeyLength),
        scaleValue: int.parse(digits.substring(valueStart, valueStart + scaleValueLength)),
      );
    }

    return ScannedCode(kind: ScannedCodeKind.product, digits: digits, lookupKey: digits);
  }

  /// Normaliza um código digitado/escaneado para guardar no produto: para
  /// etiqueta de balança guarda só a parte fixa; para produto, os dígitos.
  /// Texto só com números (e espaços/traços) vira só os dígitos; qualquer
  /// outro texto é guardado como digitado (aparado), para não perder
  /// códigos internos de outros formatos.
  static String storageKey(String raw) {
    final parsed = parse(raw);
    if (parsed != null) return parsed.lookupKey;
    final trimmed = raw.trim();
    return _numericWithSeparators.hasMatch(trimmed) ? normalize(trimmed) : trimmed;
  }

  static final _numericWithSeparators = RegExp(r'^[\d\s-]+$');
}
