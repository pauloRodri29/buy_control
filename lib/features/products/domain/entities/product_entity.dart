import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';

class ProductEntity extends SyncableFields {
  final String? code;
  final String? barcode;
  final String name;
  final String? description;
  final String? brand;
  final String categoryId;
  final String productTypeId;
  final String defaultUnitId;
  final Money? referencePrice;
  final bool isActive;

  const ProductEntity({
    required super.id,
    this.code,
    this.barcode,
    required this.name,
    this.description,
    this.brand,
    required this.categoryId,
    required this.productTypeId,
    required this.defaultUnitId,
    this.referencePrice,
    this.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncStatus,
    super.version,
  });

  ProductEntity copyWith({
    String? code,
    String? barcode,
    String? name,
    String? description,
    String? brand,
    String? categoryId,
    String? productTypeId,
    String? defaultUnitId,
    Money? referencePrice,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ProductEntity(
      id: id,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      productTypeId: productTypeId ?? this.productTypeId,
      defaultUnitId: defaultUnitId ?? this.defaultUnitId,
      referencePrice: referencePrice ?? this.referencePrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus,
      version: version + 1,
    );
  }
}
