import 'package:buy_control/core/sync/syncable.dart';

class PlanItemModel {
  final String id;
  final String? boardId;
  final String title;
  final String? description;
  final int? estimatedValueCents;
  final double position;
  final bool isPurchased;
  final DateTime? purchasedAt;
  final int? paidValueCents;
  final String? notPurchasedReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final int version;

  const PlanItemModel({
    required this.id,
    this.boardId,
    required this.title,
    this.description,
    this.estimatedValueCents,
    required this.position,
    required this.isPurchased,
    this.purchasedAt,
    this.paidValueCents,
    this.notPurchasedReason,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory PlanItemModel.fromMap(Map<String, dynamic> map) {
    final sync = SyncableFieldsData.fromMap(map);
    return PlanItemModel(
      id: sync.id,
      boardId: map['boardId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      estimatedValueCents: (map['estimatedValueCents'] as num?)?.toInt(),
      position: (map['position'] as num?)?.toDouble() ?? 0,
      isPurchased: map['isPurchased'] as bool? ?? false,
      purchasedAt: map['purchasedAt'] != null ? DateTime.parse(map['purchasedAt'] as String) : null,
      paidValueCents: (map['paidValueCents'] as num?)?.toInt(),
      notPurchasedReason: map['notPurchasedReason'] as String?,
      createdAt: sync.createdAt,
      updatedAt: sync.updatedAt,
      deletedAt: sync.deletedAt,
      syncStatus: sync.syncStatus.name,
      version: sync.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'boardId': boardId,
      'title': title,
      'description': description,
      'estimatedValueCents': estimatedValueCents,
      'position': position,
      'isPurchased': isPurchased,
      'purchasedAt': purchasedAt?.toIso8601String(),
      'paidValueCents': paidValueCents,
      'notPurchasedReason': notPurchasedReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'version': version,
    };
  }
}
