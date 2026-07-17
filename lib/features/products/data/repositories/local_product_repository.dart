import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/products/data/mappers/product_mapper.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';

class LocalProductRepository implements ProductRepository {
  final ProductHiveDataSource localDataSource;
  const LocalProductRepository({required this.localDataSource});

  @override
  Future<Result<List<ProductEntity>>> getAll({bool includeInactive = false}) async {
    try {
      final models = await localDataSource.getAll();
      final entities = models
          .map(ProductMapper.toEntity)
          .where((p) => includeInactive || (p.isActive && !p.isDeleted))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Success(entities);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<ProductEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(ProductMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(ProductEntity product) async {
    try {
      await localDataSource.put(ProductMapper.toModel(product));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> update(ProductEntity product) async {
    try {
      await localDataSource.put(ProductMapper.toModel(product));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await localDataSource.delete(id);
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }
}
