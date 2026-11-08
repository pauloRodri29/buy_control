import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';

/// Compra futura. Pode estar solta (`boardId == null`, "Sem quadro") ou
/// dentro de um quadro. [position] ordena os itens dentro da coluna; é um
/// `double` para permitir inserir entre dois itens sem renumerar a lista.
class PlanItemEntity extends SyncableFields {
  final String? boardId;
  final String title;
  final String? description;

  /// Valor estimado. `null` = ainda sem valor definido.
  final Money? estimatedValue;
  final double position;
  final bool isPurchased;
  final DateTime? purchasedAt;

  const PlanItemEntity({
    required super.id,
    this.boardId,
    required this.title,
    this.description,
    this.estimatedValue,
    required this.position,
    this.isPurchased = false,
    this.purchasedAt,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  PlanItemEntity copyWith({
    String? boardId,
    bool clearBoard = false,
    String? title,
    String? description,
    bool clearDescription = false,
    Money? estimatedValue,
    bool clearEstimatedValue = false,
    double? position,
    bool? isPurchased,
    DateTime? purchasedAt,
    bool clearPurchasedAt = false,
    DateTime? updatedAt,
  }) {
    return PlanItemEntity(
      id: id,
      boardId: clearBoard ? null : (boardId ?? this.boardId),
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      estimatedValue: clearEstimatedValue ? null : (estimatedValue ?? this.estimatedValue),
      position: position ?? this.position,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedAt: clearPurchasedAt ? null : (purchasedAt ?? this.purchasedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
