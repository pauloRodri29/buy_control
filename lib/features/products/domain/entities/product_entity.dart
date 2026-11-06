import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/syncable.dart';

class ProductEntity extends SyncableFields {
  final String? code;
  /// Códigos de barras do produto. Um produto pode ter vários (troca de
  /// embalagem, mesmo item com códigos diferentes, etiqueta de balança de
  /// cada mercado). Guardados já normalizados (`BarcodeParser.storageKey`).
  final List<String> barcodes;
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
    this.barcodes = const [],
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

  /// Primeiro código de barras, para telas que mostram só um.
  String? get barcode => barcodes.isEmpty ? null : barcodes.first;

  ProductEntity copyWith({
    String? code,
    List<String>? barcodes,
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
      barcodes: barcodes ?? this.barcodes,
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
