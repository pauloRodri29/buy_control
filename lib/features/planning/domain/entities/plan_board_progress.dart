import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';

/// Situação de um quadro em relação à sua meta. Calculado em memória a
/// partir dos itens — não é persistido.
class PlanBoardProgress {
  final Money? goal;

  /// Soma do valor de todos os itens (comprados ou não). Vale o pago,
  /// quando informado; senão o estimado.
  final Money planned;

  /// Soma do valor dos itens já marcados como comprados.
  final Money purchased;
  final int itemCount;
  final int purchasedCount;
  final int itemsWithoutValue;

  const PlanBoardProgress({
    required this.goal,
    required this.planned,
    required this.purchased,
    required this.itemCount,
    required this.purchasedCount,
    required this.itemsWithoutValue,
  });

  factory PlanBoardProgress.of(PlanBoardEntity? board, Iterable<PlanItemEntity> items) {
    var planned = Money.zero;
    var purchased = Money.zero;
    var count = 0;
    var purchasedCount = 0;
    var withoutValue = 0;

    for (final item in items) {
      count++;
      if (item.isPurchased) purchasedCount++;
      final value = item.value;
      if (value == null) {
        withoutValue++;
        continue;
      }
      planned += value;
      if (item.isPurchased) purchased += value;
    }

    return PlanBoardProgress(
      goal: board != null && board.hasGoal ? board.goal : null,
      planned: planned,
      purchased: purchased,
      itemCount: count,
      purchasedCount: purchasedCount,
      itemsWithoutValue: withoutValue,
    );
  }

  bool get hasGoal => goal != null;

  /// Quanto ainda cabe na meta (negativo quando o planejado passou dela).
  Money? get remaining => goal == null ? null : goal! - planned;

  bool get isOverGoal => goal != null && planned > goal!;

  /// Fração planejado/meta (pode passar de 1.0 quando estoura a meta).
  double? get goalRatio => goal == null ? null : planned.cents / goal!.cents;
}
