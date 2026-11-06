import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

/// Acha o produto cadastrado para um código lido. Para etiqueta de
/// balança, procura pela parte fixa da etiqueta (sem o preço/peso).
/// `Success(null)` quando nenhum produto tem esse código.
class FindProductByBarcode {
  final ProductRepository repository;
  const FindProductByBarcode(this.repository);

  Future<Result<ProductEntity?>> call(ScannedCode code) async {
    final result = await repository.getAll(includeInactive: true);
    return result.fold((products) {
      for (final product in products) {
        if (!product.isDeleted && product.barcodes.contains(code.lookupKey)) return Success(product);
      }
      return const Success(null);
    }, (f) => Failure(f));
  }
}
