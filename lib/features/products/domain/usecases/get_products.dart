import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

class GetProducts {
  final ProductRepository repository;
  const GetProducts(this.repository);

  Future<Result<List<ProductEntity>>> call({bool includeInactive = false}) async {
    final result = await repository.getAll(includeInactive: includeInactive);
    return result.fold((products) {
      final sorted = List<ProductEntity>.from(products)..sort((a, b) => a.name.compareTo(b.name));
      return Success(sorted);
    }, (f) => Failure(f));
  }
}
