import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/categories/data/mappers/category_mapper.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';

class LocalCategoryRepository implements CategoryRepository {
  final CategoryHiveDataSource localDataSource;
  const LocalCategoryRepository({required this.localDataSource});

  @override
  Future<Result<List<CategoryEntity>>> getAll({bool includeInactive = false}) async {
    try {
      final models = await localDataSource.getAll();
      final entities = models
          .map(CategoryMapper.toEntity)
          .where((c) => includeInactive || (c.isActive && !c.isDeleted))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Success(entities);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<CategoryEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(CategoryMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(CategoryEntity category) async {
    try {
      await localDataSource.put(CategoryMapper.toModel(category));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> update(CategoryEntity category) async {
    try {
      await localDataSource.put(CategoryMapper.toModel(category));
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
