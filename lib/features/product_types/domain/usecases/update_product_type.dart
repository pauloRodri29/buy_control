import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';

class UpdateProductType {
  final ProductTypeRepository repository;
  const UpdateProductType(this.repository);

  Future<Result<void>> call(ProductTypeEntity productType) async {
    if (!Validators.isNotBlank(productType.name)) {
      return const Failure(ValidationFailure('Nome do tipo de produto é obrigatório.'));
    }
    return repository.update(productType);
  }
}
