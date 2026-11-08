import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';

abstract interface class PlanBoardRepository {
  /// Quadros ordenados pela data de previsão (mais próxima primeiro).
  Future<Result<List<PlanBoardEntity>>> getAll({bool includeArchived = false});
  Future<Result<PlanBoardEntity>> getById(String id);
  Future<Result<void>> create(PlanBoardEntity board);
  Future<Result<void>> update(PlanBoardEntity board);
  Future<Result<void>> delete(String id);
}
