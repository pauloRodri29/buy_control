import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/product_barcodes.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';

class CreateProduct {
  final ProductRepository repository;
  final QuotaGuard? quota;
  const CreateProduct(this.repository, {this.quota});

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
      return Failure(ValidationFailure('products.productNameRequired'.tr));
    }
    if (!Validators.isNotBlank(categoryId)) {
      return Failure(ValidationFailure('products.productCategoryRequired'.tr));
    }
    if (!Validators.isNotBlank(productTypeId)) {
      return Failure(ValidationFailure('products.productTypeRequired'.tr));
    }
    if (!Validators.isNotBlank(defaultUnitId)) {
      return Failure(ValidationFailure('products.productDefaultUnitRequired'.tr));
    }
    if (referencePrice != null && referencePrice.cents < 0) {
      return Failure(ValidationFailure('products.referencePriceCantNegative'.tr));
    }

    if (await quota?.ensureCanAdd(ResourceKey.products) case final limit?) return Failure(limit);

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
        return Failure(ValidationFailure('products.productCodeAlreadyExists'.tr));
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
