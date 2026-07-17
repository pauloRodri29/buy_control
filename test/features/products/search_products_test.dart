import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/products/domain/usecases/search_products.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProductRepository implements ProductRepository {
  final List<ProductEntity> products;
  FakeProductRepository(this.products);

  @override
  Future<Result<void>> create(ProductEntity product) async => const Success(null);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<ProductEntity>>> getAll({bool includeInactive = false}) async => Success(products);
  @override
  Future<Result<ProductEntity>> getById(String id) async => Success(products.first);
  @override
  Future<Result<void>> update(ProductEntity product) async => const Success(null);
}

ProductEntity _product(String name, {String? code}) {
  final now = DateTime.now();
  return ProductEntity(
    id: name,
    name: name,
    code: code,
    categoryId: 'cat',
    productTypeId: 'type',
    defaultUnitId: 'un',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('SearchProducts', () {
    test('busca por nome ignora maiúsculas/minúsculas e espaços, aceita parcial', () async {
      final repository = FakeProductRepository([
        _product('Café Torrado'),
        _product('Leite Integral'),
        _product('Arroz'),
      ]);
      final usecase = SearchProducts(repository);

      final result = await usecase(query: '  CAFÉ  ');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.map((p) => p.name), ['Café Torrado']);
    });

    test('busca por código também funciona', () async {
      final repository = FakeProductRepository([_product('Detergente', code: 'DET-01')]);
      final usecase = SearchProducts(repository);

      final result = await usecase(query: 'det-01');

      expect(result.dataOrNull!.length, 1);
    });

    test('sem query retorna todos os produtos ativos', () async {
      final repository = FakeProductRepository([_product('A'), _product('B')]);
      final usecase = SearchProducts(repository);

      final result = await usecase();

      expect(result.dataOrNull!.length, 2);
    });
  });
}
