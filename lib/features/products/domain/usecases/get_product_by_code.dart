import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

class GetProductByCode {
  final ProductRepository repository;
  const GetProductByCode(this.repository);

  Future<Result<ProductEntity?>> call(String code) async {
    final result = await repository.getAll();
    return result.fold((products) {
      final normalized = code.trim().toLowerCase();
      for (final product in products) {
        final productCode = product.code?.trim().toLowerCase();
        if (productCode != null && productCode == normalized) {
          return Success(product);
        }
      }
      return const Success(null);
    }, (f) => Failure(f));
  }
}
