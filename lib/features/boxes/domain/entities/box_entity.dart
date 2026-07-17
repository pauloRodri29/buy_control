import 'package:buy_control/core/sync/syncable.dart';

class BoxEntity extends SyncableFields {
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final bool isArchived;

  const BoxEntity({
    required super.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.isArchived = false,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  BoxEntity copyWith({
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isArchived,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BoxEntity(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
