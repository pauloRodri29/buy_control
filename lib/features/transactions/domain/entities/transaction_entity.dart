import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';

class TransactionEntity extends SyncableFields {
  final String boxId;
  final String? title;
  final DateTime occurredAt;
  final String? description;
  final String? notes;
  final Money discount;
  final Money additionalCost;
  final List<TransactionItemEntity> items;

  /// Se o lançamento deve ser copiado como novo lançamento aberto quando a
  /// Box for fechada ("Repetir no próximo ciclo"). Desmarcado, ele vai só
  /// para o histórico do Fechamento.
  final bool carryOver;

  /// `null` enquanto o lançamento está "aberto" (editável, ainda não faz
  /// parte de nenhum Fechamento). Uma vez preenchido pelo fluxo de
  /// Fechamento de Box, o lançamento é histórico e congelado — ver a
  /// guarda em `UpdateTransaction`/`DeleteTransaction`.
  final String? closureId;

  /// Data de referência do Fechamento ao qual este lançamento pertence
  /// (ex.: "compras de 31/10"). Copiada do Fechamento no momento em que ele
  /// é feito, para que balanço e relatórios agrupem pelo período fechado
  /// sem precisar consultar os Fechamentos. `null` em lançamentos abertos e
  /// em lançamentos de Fechamentos antigos (anteriores a esse campo).
  final DateTime? closureReferenceDate;

  const TransactionEntity({
    required super.id,
    required this.boxId,
    this.title,
    required this.occurredAt,
    this.description,
    this.notes,
    this.discount = Money.zero,
    this.additionalCost = Money.zero,
    this.items = const [],
    this.carryOver = true,
    this.closureId,
    this.closureReferenceDate,
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

  /// Data usada em balanço/relatórios: a data de referência do Fechamento
  /// quando houver, senão a data do próprio lançamento.
  DateTime get accountingDate => closureReferenceDate ?? occurredAt;

  TransactionEntity copyWith({
    String? id,
    String? boxId,
    String? title,
    DateTime? occurredAt,
    String? description,
    String? notes,
    bool clearNotes = false,
    Money? discount,
    Money? additionalCost,
    List<TransactionItemEntity>? items,
    bool? carryOver,
    String? closureId,
    DateTime? closureReferenceDate,
    bool clearClosureId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      title: title ?? this.title,
      occurredAt: occurredAt ?? this.occurredAt,
      description: description ?? this.description,
      notes: clearNotes ? null : (notes ?? this.notes),
      discount: discount ?? this.discount,
      additionalCost: additionalCost ?? this.additionalCost,
      items: items ?? this.items,
      carryOver: carryOver ?? this.carryOver,
      closureId: clearClosureId ? null : (closureId ?? this.closureId),
      closureReferenceDate: clearClosureId ? null : (closureReferenceDate ?? this.closureReferenceDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
