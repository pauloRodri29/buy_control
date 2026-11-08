import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';

abstract interface class PlanItemRepository {
  /// Todos os itens, ordenados por [PlanItemEntity.position].
  Future<Result<List<PlanItemEntity>>> getAll();
  Future<Result<void>> create(PlanItemEntity item);
  Future<Result<void>> update(PlanItemEntity item);
  Future<Result<void>> updateAll(List<PlanItemEntity> items);
  Future<Result<void>> delete(String id);
  Future<Result<void>> deleteAll(List<String> ids);
}
