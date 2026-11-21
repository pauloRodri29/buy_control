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

  /// Data em que o quadro foi finalizado. Finalizar é definitivo: o quadro
  /// sai do kanban e vai para o Histórico.
  final DateTime? closedAt;

  /// Data em que o quadro foi cancelado (desistência). Também vai para o
  /// Histórico; os itens que já tinham sido comprados continuam valendo.
  final DateTime? cancelledAt;

  const PlanBoardEntity({
    required super.id,
    required this.title,
    this.description,
    this.goal,
    required this.targetDate,
    this.isArchived = false,
    this.closedAt,
    this.cancelledAt,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  bool get hasGoal => goal != null && !goal!.isZero;

  /// Finalizado (concluído).
  bool get isClosed => closedAt != null;

  bool get isCancelled => cancelledAt != null;

  /// Finalizado ou cancelado: fica só no Histórico, sem volta.
  bool get isFinished => isClosed || isCancelled;

  bool get isOpen => !isFinished;

  DateTime? get finishedAt => closedAt ?? cancelledAt;

  /// Previsão já passou e o quadro continua aberto.
  bool isOverdue(DateTime now) => isOpen && targetDate.isBefore(DateTime(now.year, now.month, now.day));

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
    DateTime? cancelledAt,
    DateTime? updatedAt,
  }) {
    return PlanBoardEntity(
      id: id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      goal: clearGoal ? null : (goal ?? this.goal),
      targetDate: targetDate ?? this.targetDate,
      isArchived: isArchived ?? this.isArchived,
      closedAt: closedAt ?? this.closedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
