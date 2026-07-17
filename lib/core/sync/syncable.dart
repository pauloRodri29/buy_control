import 'package:buy_control/core/sync/sync_status.dart';

/// Campos compartilhados por toda entidade persistida e sincronizável.
abstract class SyncableFields {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final int version;

  const SyncableFields({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.version = 1,
  });

  bool get isDeleted => deletedAt != null;
}

Map<String, dynamic> syncableFieldsToMap(SyncableFields fields) {
  return {
    'id': fields.id,
    'createdAt': fields.createdAt.toIso8601String(),
    'updatedAt': fields.updatedAt.toIso8601String(),
    'deletedAt': fields.deletedAt?.toIso8601String(),
    'syncStatus': fields.syncStatus.name,
    'version': fields.version,
  };
}

class SyncableFieldsData {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final int version;

  const SyncableFieldsData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory SyncableFieldsData.fromMap(Map<String, dynamic> map) {
    return SyncableFieldsData(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      syncStatus: SyncStatus.values.byName((map['syncStatus'] as String?) ?? 'synced'),
      version: (map['version'] as num?)?.toInt() ?? 1,
    );
  }
}
