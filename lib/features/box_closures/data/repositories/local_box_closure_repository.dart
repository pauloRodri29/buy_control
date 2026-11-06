import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/box_closures/data/mappers/box_closure_mapper.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';

class LocalBoxClosureRepository implements BoxClosureRepository {
  final BoxClosureHiveDataSource localDataSource;
  const LocalBoxClosureRepository({required this.localDataSource});

  @override
  Future<Result<List<BoxClosureEntity>>> getAll({String? boxId, bool includeDeleted = false}) async {
    try {
      final models = await localDataSource.getAll();
      final entities = models
          .map(BoxClosureMapper.toEntity)
          .where((c) => includeDeleted || !c.isDeleted)
          .where((c) => boxId == null || c.boxId == boxId)
          .toList()
        ..sort((a, b) {
          final byReference = b.referenceDate.compareTo(a.referenceDate);
          return byReference != 0 ? byReference : b.closedAt.compareTo(a.closedAt);
        });
      return Success(entities);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<BoxClosureEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(BoxClosureMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(BoxClosureEntity closure) async {
    try {
      await localDataSource.put(BoxClosureMapper.toModel(closure));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> update(BoxClosureEntity closure) async {
    try {
      await localDataSource.put(BoxClosureMapper.toModel(closure));
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
