import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/boxes/data/models/box_model.dart';

class BoxHiveDataSource extends HiveCollectionDataSource<BoxModel> {
  @override
  String get boxName => HiveBoxRegistry.boxes;

  @override
  BoxModel fromMap(Map<String, dynamic> map) => BoxModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(BoxModel model) => model.toMap();

  @override
  String getId(BoxModel model) => model.id;
}
