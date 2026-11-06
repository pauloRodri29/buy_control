import 'package:buy_control/core/sync/syncable.dart';
import 'package:buy_control/features/transactions/data/models/transaction_item_model.dart';

class TransactionModel {
  final String id;
  final String boxId;
  final String? title;
  final DateTime occurredAt;
  final String? description;
  final String? notes;
  final int discountCents;
  final int additionalCostCents;
  final List<Map<String, dynamic>> items;
  final bool carryOver;
  final String? closureId;
  final DateTime? closureReferenceDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final int version;

  const TransactionModel({
    required this.id,
    required this.boxId,
    this.title,
    required this.occurredAt,
    this.description,
    this.notes,
    required this.discountCents,
    required this.additionalCostCents,
    required this.items,
    this.carryOver = true,
    this.closureId,
    this.closureReferenceDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final sync = SyncableFieldsData.fromMap(map);
    return TransactionModel(
      id: sync.id,
      boxId: map['boxId'] as String,
      title: map['title'] as String?,
      occurredAt: DateTime.parse(map['occurredAt'] as String),
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      discountCents: (map['discountCents'] as num?)?.toInt() ?? 0,
      additionalCostCents: (map['additionalCostCents'] as num?)?.toInt() ?? 0,
      items: ((map['items'] as List?) ?? const [])
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .toList(),
      // Lançamentos gravados antes deste campo sempre eram copiados.
      carryOver: map['carryOver'] as bool? ?? true,
      closureId: map['closureId'] as String?,
      closureReferenceDate: map['closureReferenceDate'] == null
          ? null
          : DateTime.parse(map['closureReferenceDate'] as String),
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
      'boxId': boxId,
      'title': title,
      'occurredAt': occurredAt.toIso8601String(),
      'description': description,
      'notes': notes,
      'discountCents': discountCents,
      'additionalCostCents': additionalCostCents,
      'items': items,
      'carryOver': carryOver,
      'closureId': closureId,
      'closureReferenceDate': closureReferenceDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'version': version,
    };
  }

  List<TransactionItemModel> get itemModels =>
      items.map(TransactionItemModel.fromMap).toList();
}
