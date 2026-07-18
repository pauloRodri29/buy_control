import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';

/// Snapshot imutável de um ciclo de compras de uma Box. O detalhe (quais
/// lançamentos) não é duplicado aqui — é obtido consultando os
/// `TransactionEntity` cujo `closureId` aponta para este fechamento, que
/// nunca mais mudam depois de fechados (ver guarda em
/// `UpdateTransaction`/`DeleteTransaction`). Isso congela o histórico sem
/// duplicar dados.
class BoxClosureEntity extends SyncableFields {
  final String boxId;
  final String boxNameSnapshot;
  final DateTime closedAt;
  final String? notes;
  final Money total;
  final int transactionCount;
  final int itemCount;

  const BoxClosureEntity({
    required super.id,
    required this.boxId,
    required this.boxNameSnapshot,
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
