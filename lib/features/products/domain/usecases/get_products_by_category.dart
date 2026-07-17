import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

class GetProductsByCategory {
  final ProductRepository repository;
  const GetProductsByCategory(this.repository);

  Future<Result<List<ProductEntity>>> call(String categoryId) async {
    final result = await repository.getAll();
    return result.fold(
      (products) => Success(products.where((p) => p.categoryId == categoryId).toList()),
      (f) => Failure(f),
    );
  }
}
