import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';

class CreateProductType {
  final ProductTypeRepository repository;
  final QuotaGuard? quota;
  const CreateProductType(this.repository, {this.quota});

  Future<Result<ProductTypeEntity>> call({
    required String name,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return Failure(ValidationFailure('productTypes.productTypeNameRequired'.tr));
    }

    if (await quota?.ensureCanAdd(ResourceKey.productTypes) case final limit?) return Failure(limit);

    final now = DateTime.now();
    final productType = ProductTypeEntity(
      id: IdGenerator.generate(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final result = await repository.create(productType);
    return result.fold((_) => Success(productType), (f) => Failure(f));
  }
}
