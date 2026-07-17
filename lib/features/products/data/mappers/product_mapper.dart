import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/sync/sync_status.dart';
import 'package:buy_control/features/products/data/models/product_model.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';

class ProductMapper {
  static ProductEntity toEntity(ProductModel model) {
    return ProductEntity(
      id: model.id,
      code: model.code,
      barcode: model.barcode,
      name: model.name,
      description: model.description,
      brand: model.brand,
      categoryId: model.categoryId,
      productTypeId: model.productTypeId,
      defaultUnitId: model.defaultUnitId,
      referencePrice: model.referencePriceCents != null ? Money(model.referencePriceCents!) : null,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      syncStatus: SyncStatus.values.byName(model.syncStatus),
      version: model.version,
    );
  }

  static ProductModel toModel(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      code: entity.code,
      barcode: entity.barcode,
      name: entity.name,
      description: entity.description,
      brand: entity.brand,
      categoryId: entity.categoryId,
      productTypeId: entity.productTypeId,
      defaultUnitId: entity.defaultUnitId,
      referencePriceCents: entity.referencePrice?.cents,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      syncStatus: entity.syncStatus.name,
      version: entity.version,
    );
  }
}
