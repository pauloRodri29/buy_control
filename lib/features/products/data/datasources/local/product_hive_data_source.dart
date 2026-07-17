import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/products/data/models/product_model.dart';

class ProductHiveDataSource extends HiveCollectionDataSource<ProductModel> {
  @override
  String get boxName => HiveBoxRegistry.products;

  @override
  ProductModel fromMap(Map<String, dynamic> map) => ProductModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ProductModel model) => model.toMap();

  @override
  String getId(ProductModel model) => model.id;
}
