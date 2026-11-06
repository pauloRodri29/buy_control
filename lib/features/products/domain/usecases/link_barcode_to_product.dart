import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/product_barcodes.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

/// Adiciona um código lido aos códigos de um produto já cadastrado (ex.:
/// embalagem nova, ou a etiqueta de balança de um mercado), para que as
/// próximas leituras reconheçam o produto direto.
class LinkBarcodeToProduct {
  final ProductRepository repository;
  const LinkBarcodeToProduct(this.repository);

  Future<Result<ProductEntity>> call({required String productId, required ScannedCode code}) async {
    final productResult = await repository.getById(productId);
    if (productResult.isFailure) return Failure(productResult.failureOrNull!);
    final product = productResult.dataOrNull!;
    if (product.barcodes.contains(code.lookupKey)) return Success(product);

    final allResult = await repository.getAll(includeInactive: true);
    if (allResult.isFailure) return Failure(allResult.failureOrNull!);
    final conflict = ProductBarcodes.findConflict(
      allResult.dataOrNull!,
      barcodes: [code.lookupKey],
      exceptProductId: product.id,
    );
    if (conflict != null) return Failure(ValidationFailure(ProductBarcodes.conflictMessage(conflict)));

    final updated = product.copyWith(barcodes: [...product.barcodes, code.lookupKey]);
    final saveResult = await repository.update(updated);
    return saveResult.fold((_) => Success(updated), (f) => Failure(f));
  }
}
