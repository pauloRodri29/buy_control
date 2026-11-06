import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/product_barcodes.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

class CreateProduct {
  final ProductRepository repository;
  const CreateProduct(this.repository);

  Future<Result<ProductEntity>> call({
    String? code,
    List<String> barcodes = const [],
    required String name,
    String? description,
    String? brand,
    required String categoryId,
    required String productTypeId,
    required String defaultUnitId,
    Money? referencePrice,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return const Failure(ValidationFailure('Nome do produto é obrigatório.'));
    }
    if (!Validators.isNotBlank(categoryId)) {
      return const Failure(ValidationFailure('Categoria do produto é obrigatória.'));
    }
    if (!Validators.isNotBlank(productTypeId)) {
      return const Failure(ValidationFailure('Tipo do produto é obrigatório.'));
    }
    if (!Validators.isNotBlank(defaultUnitId)) {
      return const Failure(ValidationFailure('Unidade padrão do produto é obrigatória.'));
    }
    if (referencePrice != null && referencePrice.cents < 0) {
      return const Failure(ValidationFailure('Preço de referência não pode ser negativo.'));
    }

    final trimmedCode = code?.trim();
    final normalizedBarcodes = ProductBarcodes.normalize(barcodes);

    if ((trimmedCode != null && trimmedCode.isNotEmpty) || normalizedBarcodes.isNotEmpty) {
      final existingResult = await repository.getAll(includeInactive: true);
      if (existingResult.isFailure) {
        return Failure(existingResult.failureOrNull!);
      }
      final existing = existingResult.dataOrNull!;
      final sameCode = trimmedCode != null &&
          trimmedCode.isNotEmpty &&
          existing.any((p) => !p.isDeleted && p.code?.trim().toLowerCase() == trimmedCode.toLowerCase());
      if (sameCode) {
        return const Failure(ValidationFailure('Já existe um produto com este código.'));
      }
      final conflict = ProductBarcodes.findConflict(existing, barcodes: normalizedBarcodes);
      if (conflict != null) {
        return Failure(ValidationFailure(ProductBarcodes.conflictMessage(conflict)));
      }
    }

    final now = DateTime.now();
    final product = ProductEntity(
      id: IdGenerator.generate(),
      code: trimmedCode == null || trimmedCode.isEmpty ? null : trimmedCode,
      barcodes: normalizedBarcodes,
      name: name.trim(),
      description: description,
      brand: brand,
      categoryId: categoryId,
      productTypeId: productTypeId,
      defaultUnitId: defaultUnitId,
      referencePrice: referencePrice,
      createdAt: now,
      updatedAt: now,
    );

    final result = await repository.create(product);
    return result.fold((_) => Success(product), (f) => Failure(f));
  }
}
