import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/mappers/box_mapper.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';

class LocalBoxRepository implements BoxRepository {
  final BoxHiveDataSource localDataSource;
  const LocalBoxRepository({required this.localDataSource});

  @override
  Future<Result<List<BoxEntity>>> getAll({bool includeArchived = false, bool includeDeleted = false}) async {
    try {
      final models = await localDataSource.getAll();
      final entities = models
          .map(BoxMapper.toEntity)
          .where((b) => (includeDeleted || !b.isDeleted) && (includeArchived || !b.isArchived))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Success(entities);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<BoxEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(BoxMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(BoxEntity box) async {
    try {
      await localDataSource.put(BoxMapper.toModel(box));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> update(BoxEntity box) async {
    try {
      await localDataSource.put(BoxMapper.toModel(box));
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
