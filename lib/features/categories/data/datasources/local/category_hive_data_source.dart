import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/categories/data/models/category_model.dart';

class CategoryHiveDataSource extends HiveCollectionDataSource<CategoryModel> {
  @override
  String get boxName => HiveBoxRegistry.categories;

  @override
  CategoryModel fromMap(Map<String, dynamic> map) => CategoryModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(CategoryModel model) => model.toMap();

  @override
  String getId(CategoryModel model) => model.id;
}
