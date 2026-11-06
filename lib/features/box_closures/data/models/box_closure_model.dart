import 'package:buy_control/core/sync/syncable.dart';

class BoxClosureModel {
  final String id;
  final String boxId;
  final String boxNameSnapshot;
  final DateTime referenceDate;
  final DateTime closedAt;
  final String? notes;
  final int totalCents;
  final int transactionCount;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final int version;

  const BoxClosureModel({
    required this.id,
    required this.boxId,
    required this.boxNameSnapshot,
    required this.referenceDate,
    required this.closedAt,
    this.notes,
    required this.totalCents,
    required this.transactionCount,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory BoxClosureModel.fromMap(Map<String, dynamic> map) {
    final sync = SyncableFieldsData.fromMap(map);
    final closedAt = DateTime.parse(map['closedAt'] as String);
    return BoxClosureModel(
      id: sync.id,
      boxId: map['boxId'] as String,
      boxNameSnapshot: map['boxNameSnapshot'] as String,
      // Fechamentos anteriores a este campo usam o dia em que foram feitos.
      referenceDate: map['referenceDate'] == null
          ? DateTime(closedAt.year, closedAt.month, closedAt.day)
          : DateTime.parse(map['referenceDate'] as String),
      closedAt: closedAt,
      notes: map['notes'] as String?,
      totalCents: (map['totalCents'] as num?)?.toInt() ?? 0,
      transactionCount: (map['transactionCount'] as num?)?.toInt() ?? 0,
      itemCount: (map['itemCount'] as num?)?.toInt() ?? 0,
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
      'boxNameSnapshot': boxNameSnapshot,
      'referenceDate': referenceDate.toIso8601String(),
      'closedAt': closedAt.toIso8601String(),
      'notes': notes,
      'totalCents': totalCents,
      'transactionCount': transactionCount,
      'itemCount': itemCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'version': version,
    };
  }
}
