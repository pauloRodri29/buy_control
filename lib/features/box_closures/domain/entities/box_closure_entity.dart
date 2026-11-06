import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';

/// Registro definitivo de um ciclo de compras de uma Box (normalmente o
/// mês). Não pode ser reaberto nem editado. O detalhe (quais lançamentos)
/// não é duplicado aqui — é obtido consultando os `TransactionEntity` cujo
/// `closureId` aponta para este fechamento, que nunca mais mudam depois de
/// fechados (ver guarda em `UpdateTransaction`/`DeleteTransaction`).
class BoxClosureEntity extends SyncableFields {
  final String boxId;
  final String boxNameSnapshot;

  /// Data a que as compras se referem, escolhida pelo usuário ao fechar
  /// (só a data, sem horário). É ela que balanço e relatórios usam.
  final DateTime referenceDate;

  /// Momento real em que o usuário fechou a Box.
  final DateTime closedAt;
  final String? notes;
  final Money total;
  final int transactionCount;
  final int itemCount;

  const BoxClosureEntity({
    required super.id,
    required this.boxId,
    required this.boxNameSnapshot,
    required this.referenceDate,
    required this.closedAt,
    this.notes,
    required this.total,
    required this.transactionCount,
    required this.itemCount,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  BoxClosureEntity copyWith({
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BoxClosureEntity(
      id: id,
      boxId: boxId,
      boxNameSnapshot: boxNameSnapshot,
      referenceDate: referenceDate,
      closedAt: closedAt,
      notes: notes ?? this.notes,
      total: total,
      transactionCount: transactionCount,
      itemCount: itemCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
