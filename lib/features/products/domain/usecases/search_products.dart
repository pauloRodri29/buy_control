import 'package:buy_control/core/extensions/string_extensions.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

class SearchProducts {
  final ProductRepository repository;
  const SearchProducts(this.repository);

  Future<Result<List<ProductEntity>>> call({
    String? query,
    String? categoryId,
    String? productTypeId,
    bool includeInactive = false,
  }) async {
    final result = await repository.getAll(includeInactive: includeInactive);
    return result.fold((products) {
      var filtered = products;

      if (query != null && query.trim().isNotEmpty) {
        filtered = filtered.where((p) => _matches(p, query)).toList();
      }
      if (categoryId != null && categoryId.trim().isNotEmpty) {
        filtered = filtered.where((p) => p.categoryId == categoryId).toList();
      }
      if (productTypeId != null && productTypeId.trim().isNotEmpty) {
        filtered = filtered.where((p) => p.productTypeId == productTypeId).toList();
      }

      return Success(filtered);
    }, (f) => Failure(f));
  }

  bool _matches(ProductEntity product, String query) {
    return product.id.containsSearchTerm(query) ||
        (product.code?.containsSearchTerm(query) ?? false) ||
        (product.barcode?.containsSearchTerm(query) ?? false) ||
        product.name.containsSearchTerm(query) ||
        (product.brand?.containsSearchTerm(query) ?? false);
  }
}
