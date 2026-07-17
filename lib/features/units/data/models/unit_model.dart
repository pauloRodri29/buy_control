import 'package:buy_control/core/sync/syncable.dart';

class UnitModel {
  final String id;
  final String name;
  final String abbreviation;
  final bool allowsDecimal;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final int version;

  const UnitModel({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.allowsDecimal,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    final sync = SyncableFieldsData.fromMap(map);
    return UnitModel(
      id: sync.id,
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      allowsDecimal: map['allowsDecimal'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
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
      'name': name,
      'abbreviation': abbreviation,
      'allowsDecimal': allowsDecimal,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'version': version,
    };
  }
}
