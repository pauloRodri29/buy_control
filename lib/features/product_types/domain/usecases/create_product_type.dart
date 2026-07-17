import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';

class CreateProductType {
  final ProductTypeRepository repository;
  const CreateProductType(this.repository);

  Future<Result<ProductTypeEntity>> call({
    required String name,
  }) async {
    if (!Validators.isNotBlank(name)) {
      return const Failure(ValidationFailure('Nome do tipo de produto é obrigatório.'));
    }

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
