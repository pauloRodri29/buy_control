import 'package:buy_control/core/sync/syncable.dart';

class CategoryEntity extends SyncableFields {
  final String name;
  final String? icon;
  final bool isActive;

  const CategoryEntity({
    required super.id,
    required this.name,
    this.icon,
    this.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  CategoryEntity copyWith({
    String? name,
    String? icon,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CategoryEntity(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
