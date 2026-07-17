import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:buy_control/features/units/data/mappers/unit_mapper.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

class LocalUnitRepository implements UnitRepository {
  final UnitHiveDataSource localDataSource;
  const LocalUnitRepository({required this.localDataSource});

  @override
  Future<Result<List<UnitEntity>>> getAll({bool includeInactive = false}) async {
    try {
      final models = await localDataSource.getAll();
      final entities = models
          .map(UnitMapper.toEntity)
          .where((u) => includeInactive || (u.isActive && !u.isDeleted))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Success(entities);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<UnitEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(UnitMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(UnitEntity unit) async {
    try {
      await localDataSource.put(UnitMapper.toModel(unit));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> update(UnitEntity unit) async {
    try {
      await localDataSource.put(UnitMapper.toModel(unit));
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
