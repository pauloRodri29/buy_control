import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/product_types/data/models/product_type_model.dart';

class ProductTypeHiveDataSource extends HiveCollectionDataSource<ProductTypeModel> {
  @override
  String get boxName => HiveBoxRegistry.productTypes;

  @override
  ProductTypeModel fromMap(Map<String, dynamic> map) => ProductTypeModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ProductTypeModel model) => model.toMap();

  @override
  String getId(ProductTypeModel model) => model.id;
}
