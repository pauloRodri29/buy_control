import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
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
    final barcode = product.barcode?.trim();

    if ((code != null && code.isNotEmpty) || (barcode != null && barcode.isNotEmpty)) {
      final existingResult = await repository.getAll();
      if (existingResult.isFailure) {
        return Failure(existingResult.failureOrNull!);
      }
      final existing = existingResult.dataOrNull!;
      final duplicate = existing.any((p) {
        if (p.id == product.id) return false;
        final sameCode = code != null &&
            code.isNotEmpty &&
            p.code != null &&
            p.code!.trim().toLowerCase() == code.toLowerCase();
        final sameBarcode = barcode != null &&
            barcode.isNotEmpty &&
            p.barcode != null &&
            p.barcode!.trim().toLowerCase() == barcode.toLowerCase();
        return sameCode || sameBarcode;
      });
      if (duplicate) {
        return const Failure(ValidationFailure('Já existe um produto com este código ou código de barras.'));
      }
    }

    return repository.update(product);
  }
}
