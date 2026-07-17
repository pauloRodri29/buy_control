import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';

class GetProductTypes {
  final ProductTypeRepository repository;
  const GetProductTypes(this.repository);

  Future<Result<List<ProductTypeEntity>>> call({bool includeInactive = false}) {
    return repository.getAll(includeInactive: includeInactive);
  }
}
