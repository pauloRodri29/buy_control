import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';

/// Regras de códigos de barras de produtos, compartilhadas pelos casos de
/// uso de criar/editar/vincular.
class ProductBarcodes {
  ProductBarcodes._();

  /// Normaliza (ver `BarcodeParser.storageKey`), remove vazios e repetidos,
  /// preservando a ordem.
  static List<String> normalize(Iterable<String> raw) {
    final result = <String>[];
    for (final code in raw) {
      final key = BarcodeParser.storageKey(code);
      if (key.isNotEmpty && !result.contains(key)) result.add(key);
    }
    return result;
  }

  /// Separa um texto com vários códigos (vírgula, ponto e vírgula, espaço
  /// ou quebra de linha).
  static List<String> parseList(String text) => normalize(text.split(RegExp(r'[,;\s]+')));

  /// Outro produto (ativo ou não, ignorando excluídos) que já usa algum dos
  /// [barcodes]; `null` se nenhum. Um código só pode identificar um produto.
  static ProductEntity? findConflict(
    List<ProductEntity> products, {
    required List<String> barcodes,
    String? exceptProductId,
  }) {
    if (barcodes.isEmpty) return null;
    for (final product in products) {
      if (product.id == exceptProductId || product.isDeleted) continue;
      if (product.barcodes.any(barcodes.contains)) return product;
    }
    return null;
  }

  static String conflictMessage(ProductEntity other) =>
      'Este código de barras já pertence ao produto "${other.name}".';
}
