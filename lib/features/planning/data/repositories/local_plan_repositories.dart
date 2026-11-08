import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/planning/data/datasources/local/plan_hive_data_sources.dart';
import 'package:buy_control/features/planning/data/mappers/plan_mappers.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';

Future<Result<T>> _guard<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } catch (_) {
    return const Failure(CacheFailure());
  }
}

class LocalPlanBoardRepository implements PlanBoardRepository {
  final PlanBoardHiveDataSource localDataSource;
  const LocalPlanBoardRepository({required this.localDataSource});

  @override
  Future<Result<List<PlanBoardEntity>>> getAll({bool includeArchived = false}) {
    return _guard(() async {
      final models = await localDataSource.getAll();
      return models
          .map(PlanBoardMapper.toEntity)
          .where((b) => !b.isDeleted && (includeArchived || !b.isArchived))
          .toList()
        ..sort((a, b) {
          final byDate = a.targetDate.compareTo(b.targetDate);
          return byDate != 0 ? byDate : a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
    });
  }

  @override
  Future<Result<PlanBoardEntity>> getById(String id) async {
    try {
      final model = await localDataSource.getById(id);
      if (model == null) return const Failure(NotFoundFailure());
      return Success(PlanBoardMapper.toEntity(model));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> create(PlanBoardEntity board) => _guard(() => localDataSource.put(PlanBoardMapper.toModel(board)));

  @override
  Future<Result<void>> update(PlanBoardEntity board) => _guard(() => localDataSource.put(PlanBoardMapper.toModel(board)));

  @override
  Future<Result<void>> delete(String id) => _guard(() => localDataSource.delete(id));
}

class LocalPlanItemRepository implements PlanItemRepository {
  final PlanItemHiveDataSource localDataSource;
  const LocalPlanItemRepository({required this.localDataSource});

  @override
  Future<Result<List<PlanItemEntity>>> getAll() {
    return _guard(() async {
      final models = await localDataSource.getAll();
      return models.map(PlanItemMapper.toEntity).where((i) => !i.isDeleted).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    });
  }

  @override
  Future<Result<void>> create(PlanItemEntity item) => _guard(() => localDataSource.put(PlanItemMapper.toModel(item)));

  @override
  Future<Result<void>> update(PlanItemEntity item) => _guard(() => localDataSource.put(PlanItemMapper.toModel(item)));

  @override
  Future<Result<void>> updateAll(List<PlanItemEntity> items) {
    return _guard(() => localDataSource.putAll(items.map(PlanItemMapper.toModel).toList()));
  }

  @override
  Future<Result<void>> delete(String id) => _guard(() => localDataSource.delete(id));

  @override
  Future<Result<void>> deleteAll(List<String> ids) {
    return _guard(() async {
      for (final id in ids) {
        await localDataSource.delete(id);
      }
    });
  }
}
