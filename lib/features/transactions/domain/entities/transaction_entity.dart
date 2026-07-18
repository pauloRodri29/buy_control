import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';

class TransactionEntity extends SyncableFields {
  final String boxId;
  final String? title;
  final DateTime occurredAt;
  final String? notes;
  final Money discount;
  final Money additionalCost;
  final List<TransactionItemEntity> items;

  /// `null` enquanto o lançamento está "aberto" (editável, ainda não faz
  /// parte de nenhum Fechamento). Uma vez preenchido pelo fluxo de
  /// Fechamento de Box, o lançamento é histórico e congelado — ver a
  /// guarda em `UpdateTransaction`/`DeleteTransaction`.
  final String? closureId;

  const TransactionEntity({
    required super.id,
    required this.boxId,
    this.title,
    required this.occurredAt,
    this.notes,
    this.discount = Money.zero,
    this.additionalCost = Money.zero,
    this.items = const [],
    this.closureId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  // Soma dos totais de cada item, antes de aplicar desconto/custo adicional
  // do lançamento como um todo.
  Money get itemsTotal => items.fold(Money.zero, (sum, item) => sum + item.total);
  Money get total => itemsTotal - discount + additionalCost;
  int get itemCount => items.length;
  bool get isClosed => closureId != null;

  TransactionEntity copyWith({
    String? boxId,
    String? title,
    DateTime? occurredAt,
    String? notes,
    Money? discount,
    Money? additionalCost,
    List<TransactionItemEntity>? items,
    String? closureId,
    bool clearClosureId = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TransactionEntity(
      id: id,
      boxId: boxId ?? this.boxId,
      title: title ?? this.title,
      occurredAt: occurredAt ?? this.occurredAt,
      notes: notes ?? this.notes,
      discount: discount ?? this.discount,
      additionalCost: additionalCost ?? this.additionalCost,
      items: items ?? this.items,
      closureId: clearClosureId ? null : (closureId ?? this.closureId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
