import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/product_types/data/mappers/product_type_mapper.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';

class LocalProductTypeRepository implements ProductTypeRepository {
  final ProductTypeHiveDataSource localDataSource;
  const LocalProductTypeRepository({required this.localDataSource});

  @override
  Future<Result<List<ProductTypeEntity>>> getAll({bool includeInactive = false}) async {
    try {
      final models = await localDataSource.getAll();
      final entities = models
          .map(ProductTypeMapper.toEntity)
          .where((p) => includeInactive || (p.isActive && !p.isDeleted))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Success(entities);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<ProductTypeEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(ProductTypeMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(ProductTypeEntity productType) async {
    try {
      await localDataSource.put(ProductTypeMapper.toModel(productType));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> update(ProductTypeEntity productType) async {
    try {
      await localDataSource.put(ProductTypeMapper.toModel(productType));
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
