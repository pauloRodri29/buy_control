import 'package:buy_control/core/sync/syncable.dart';

class ProductModel {
  final String id;
  final String? code;
  final List<String> barcodes;
  final String name;
  final String? description;
  final String? brand;
  final String categoryId;
  final String productTypeId;
  final String defaultUnitId;
  final int? referencePriceCents;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final int version;

  const ProductModel({
    required this.id,
    this.code,
    this.barcodes = const [],
    required this.name,
    this.description,
    this.brand,
    required this.categoryId,
    required this.productTypeId,
    required this.defaultUnitId,
    this.referencePriceCents,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final sync = SyncableFieldsData.fromMap(map);
    return ProductModel(
      id: sync.id,
      code: map['code'] as String?,
      barcodes: _readBarcodes(map),
      name: map['name'] as String,
      description: map['description'] as String?,
      brand: map['brand'] as String?,
      categoryId: map['categoryId'] as String,
      productTypeId: map['productTypeId'] as String,
      defaultUnitId: map['defaultUnitId'] as String,
      referencePriceCents: (map['referencePriceCents'] as num?)?.toInt(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: sync.createdAt,
      updatedAt: sync.updatedAt,
      deletedAt: sync.deletedAt,
      syncStatus: sync.syncStatus.name,
      version: sync.version,
    );
  }

  /// Lê a lista `barcodes`; registros antigos só têm o campo único `barcode`.
  static List<String> _readBarcodes(Map<String, dynamic> map) {
    final list = map['barcodes'];
    if (list is List) {
      return list.whereType<String>().where((c) => c.trim().isNotEmpty).toList();
    }
    final single = map['barcode'] as String?;
    return single == null || single.trim().isEmpty ? const [] : [single.trim()];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'barcodes': barcodes,
      // Mantido para backups lidos por versões anteriores do app.
      'barcode': barcodes.isEmpty ? null : barcodes.first,
      'name': name,
      'description': description,
      'brand': brand,
      'categoryId': categoryId,
      'productTypeId': productTypeId,
      'defaultUnitId': defaultUnitId,
      'referencePriceCents': referencePriceCents,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'version': version,
    };
  }
}
