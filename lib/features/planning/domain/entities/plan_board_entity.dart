import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';

/// Quadro de planejamento de compras: um contexto ("Dezembro", "Fim de
/// ano"...) com data de previsão e, opcionalmente, uma meta de gasto.
/// Os quadros são exibidos ordenados pela [targetDate].
class PlanBoardEntity extends SyncableFields {
  final String title;
  final String? description;

  /// Valor máximo que se pretende gastar neste contexto. `null` = sem meta.
  final Money? goal;
  final DateTime targetDate;
  final bool isArchived;

  /// Data em que o quadro foi fechado (todos os itens marcados como
  /// comprados). `null` = quadro em aberto.
  final DateTime? closedAt;

  const PlanBoardEntity({
    required super.id,
    required this.title,
    this.description,
    this.goal,
    required this.targetDate,
    this.isArchived = false,
    this.closedAt,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  bool get hasGoal => goal != null && !goal!.isZero;

  bool get isClosed => closedAt != null;

  /// `clearDescription`/`clearGoal` permitem remover um valor opcional, já
  /// que passar `null` em [copyWith] significa "manter o atual".
  PlanBoardEntity copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    Money? goal,
    bool clearGoal = false,
    DateTime? targetDate,
    bool? isArchived,
    DateTime? closedAt,
    bool clearClosedAt = false,
    DateTime? updatedAt,
  }) {
    return PlanBoardEntity(
      id: id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      goal: clearGoal ? null : (goal ?? this.goal),
      targetDate: targetDate ?? this.targetDate,
      isArchived: isArchived ?? this.isArchived,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
