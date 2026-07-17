import 'package:buy_control/core/sync/syncable.dart';

class ProductTypeEntity extends SyncableFields {
  final String name;
  final bool isActive;

  const ProductTypeEntity({
    required super.id,
    required this.name,
    this.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  ProductTypeEntity copyWith({
    String? name,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ProductTypeEntity(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
