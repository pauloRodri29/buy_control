import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/data/mappers/product_mapper.dart';
import 'package:buy_control/features/products/data/models/product_model.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/products/domain/usecases/create_product.dart';
import 'package:buy_control/features/products/domain/usecases/find_product_by_barcode.dart';
import 'package:buy_control/features/products/domain/usecases/link_barcode_to_product.dart';
import 'package:buy_control/features/products/domain/usecases/update_product.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  final Map<String, ProductEntity> store = {};

  @override
  Future<Result<void>> create(ProductEntity product) async {
    store[product.id] = product;
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    store.remove(id);
    return const Success(null);
  }

  @override
  Future<Result<List<ProductEntity>>> getAll({bool includeInactive = false}) async =>
      Success(store.values.where((p) => includeInactive || p.isActive).toList());

  @override
  Future<Result<ProductEntity>> getById(String id) async {
    final product = store[id];
    return product == null ? const Failure(NotFoundFailure()) : Success(product);
  }

  @override
  Future<Result<void>> update(ProductEntity product) async {
    store[product.id] = product;
    return const Success(null);
  }
}

ProductEntity _product(String id, {List<String> barcodes = const [], bool isActive = true}) {
  final now = DateTime(2026, 1, 1);
  return ProductEntity(
    id: id,
    name: 'Produto $id',
    barcodes: barcodes,
    categoryId: 'c',
    productTypeId: 't',
    defaultUnitId: 'u',
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const ean = '4006381333931';
  const otherEan = '73513537';
  const scaleLabel = '2001234012348';

  group('Códigos de barras do produto', () {
    test('produto pode ter vários códigos e é encontrado por qualquer um', () async {
      final repository = _FakeProductRepository()..store['p1'] = _product('p1', barcodes: [ean, otherEan]);
      final find = FindProductByBarcode(repository);

      expect((await find(BarcodeParser.parse(ean)!)).dataOrNull?.id, 'p1');
      expect((await find(BarcodeParser.parse(otherEan)!)).dataOrNull?.id, 'p1');
      expect((await find(BarcodeParser.parse('036000291452')!)).dataOrNull, isNull);
    });

    test('etiqueta de balança é encontrada pela parte fixa, qualquer que seja o valor', () async {
      final repository = _FakeProductRepository()..store['carne'] = _product('carne', barcodes: ['2001234']);
      final found = await FindProductByBarcode(repository)(BarcodeParser.parse('2001234056786')!);
      expect(found.dataOrNull?.id, 'carne');
    });

    test('criar produto normaliza, remove repetidos e rejeita código de outro produto', () async {
      final repository = _FakeProductRepository()..store['p1'] = _product('p1', barcodes: [ean]);
      final create = CreateProduct(repository);

      final ok = await create(
        name: 'Novo',
        barcodes: [' 7351-3537 ', otherEan, scaleLabel],
        categoryId: 'c',
        productTypeId: 't',
        defaultUnitId: 'u',
      );
      expect(ok.dataOrNull!.barcodes, [otherEan, '2001234']);

      final duplicate = await create(
        name: 'Outro',
        barcodes: [ean],
        categoryId: 'c',
        productTypeId: 't',
        defaultUnitId: 'u',
      );
      expect(duplicate.isFailure, isTrue);
    });

    test('código de produto inativo também conta como já usado', () async {
      final repository = _FakeProductRepository()..store['old'] = _product('old', barcodes: [ean], isActive: false);
      final updated = await UpdateProduct(repository)(_product('p2', barcodes: [ean]));
      expect(updated.isFailure, isTrue);
    });

    test('vincular adiciona o código lido ao produto, sem perder os anteriores', () async {
      final repository = _FakeProductRepository()..store['p1'] = _product('p1', barcodes: [ean]);
      final result = await LinkBarcodeToProduct(repository)(
        productId: 'p1',
        code: BarcodeParser.parse(otherEan)!,
      );
      expect(result.dataOrNull!.barcodes, [ean, otherEan]);
      expect(repository.store['p1']!.barcodes, [ean, otherEan]);
    });

    test('vincular falha se o código já pertence a outro produto', () async {
      final repository = _FakeProductRepository()
        ..store['p1'] = _product('p1', barcodes: [ean])
        ..store['p2'] = _product('p2');
      final result = await LinkBarcodeToProduct(repository)(productId: 'p2', code: BarcodeParser.parse(ean)!);
      expect(result.isFailure, isTrue);
      expect(repository.store['p2']!.barcodes, isEmpty);
    });

    test('produtos salvos com um único código continuam sendo lidos', () {
      final legacy = ProductModel.fromMap({
        'id': 'p1',
        'barcode': ean,
        'name': 'Café',
        'categoryId': 'c',
        'productTypeId': 't',
        'defaultUnitId': 'u',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      });
      final entity = ProductMapper.toEntity(legacy);
      expect(entity.barcodes, [ean]);
      expect(ProductMapper.toModel(entity).toMap()['barcodes'], [ean]);
    });
  });
}
