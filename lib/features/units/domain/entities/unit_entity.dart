import 'package:buy_control/core/sync/syncable.dart';

class UnitEntity extends SyncableFields {
  final String name;
  final String abbreviation;
  final bool allowsDecimal;
  final bool isActive;

  const UnitEntity({
    required super.id,
    required this.name,
    required this.abbreviation,
    this.allowsDecimal = false,
    this.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  UnitEntity copyWith({
    String? name,
    String? abbreviation,
    bool? allowsDecimal,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return UnitEntity(
      id: id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      allowsDecimal: allowsDecimal ?? this.allowsDecimal,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
