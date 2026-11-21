import 'package:buy_control/core/sync/syncable.dart';

class PlanBoardModel {
  final String id;
  final String title;
  final String? description;
  final int? goalCents;
  final DateTime targetDate;
  final bool isArchived;
  final DateTime? closedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final int version;

  const PlanBoardModel({
    required this.id,
    required this.title,
    this.description,
    this.goalCents,
    required this.targetDate,
    required this.isArchived,
    this.closedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory PlanBoardModel.fromMap(Map<String, dynamic> map) {
    final sync = SyncableFieldsData.fromMap(map);
    return PlanBoardModel(
      id: sync.id,
      title: map['title'] as String,
      description: map['description'] as String?,
      goalCents: (map['goalCents'] as num?)?.toInt(),
      targetDate: DateTime.parse(map['targetDate'] as String),
      isArchived: map['isArchived'] as bool? ?? false,
      closedAt: map['closedAt'] != null ? DateTime.parse(map['closedAt'] as String) : null,
      cancelledAt: map['cancelledAt'] != null ? DateTime.parse(map['cancelledAt'] as String) : null,
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
      'title': title,
      'description': description,
      'goalCents': goalCents,
      'targetDate': targetDate.toIso8601String(),
      'isArchived': isArchived,
      'closedAt': closedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'version': version,
    };
  }
}
