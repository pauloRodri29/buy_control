import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/product_barcodes.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

class UpdateProduct {
  final ProductRepository repository;
  const UpdateProduct(this.repository);

  Future<Result<void>> call(ProductEntity product) async {
    if (!Validators.isNotBlank(product.name)) {
      return const Failure(ValidationFailure('Nome do produto é obrigatório.'));
    }
    if (!Validators.isNotBlank(product.categoryId)) {
      return const Failure(ValidationFailure('Categoria do produto é obrigatória.'));
    }
    if (!Validators.isNotBlank(product.productTypeId)) {
      return const Failure(ValidationFailure('Tipo do produto é obrigatório.'));
    }
    if (!Validators.isNotBlank(product.defaultUnitId)) {
      return const Failure(ValidationFailure('Unidade padrão do produto é obrigatória.'));
    }
    if (product.referencePrice != null && product.referencePrice!.cents < 0) {
      return const Failure(ValidationFailure('Preço de referência não pode ser negativo.'));
    }

    final code = product.code?.trim();
    final barcodes = ProductBarcodes.normalize(product.barcodes);

    if ((code != null && code.isNotEmpty) || barcodes.isNotEmpty) {
      final existingResult = await repository.getAll(includeInactive: true);
      if (existingResult.isFailure) {
        return Failure(existingResult.failureOrNull!);
      }
      final existing = existingResult.dataOrNull!;
      final sameCode = code != null &&
          code.isNotEmpty &&
          existing.any(
            (p) => p.id != product.id && !p.isDeleted && p.code?.trim().toLowerCase() == code.toLowerCase(),
          );
      if (sameCode) {
        return const Failure(ValidationFailure('Já existe um produto com este código.'));
      }
      final conflict = ProductBarcodes.findConflict(existing, barcodes: barcodes, exceptProductId: product.id);
      if (conflict != null) {
        return Failure(ValidationFailure(ProductBarcodes.conflictMessage(conflict)));
      }
    }

    // copyWith incrementa a versão; só usa quando a normalização mudou algo.
    final alreadyNormalized = barcodes.join('|') == product.barcodes.join('|');
    return repository.update(
      alreadyNormalized ? product : product.copyWith(barcodes: barcodes, updatedAt: product.updatedAt),
    );
  }
}
