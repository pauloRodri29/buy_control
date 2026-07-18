import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/box_closures/data/models/box_closure_model.dart';

class BoxClosureHiveDataSource extends HiveCollectionDataSource<BoxClosureModel> {
  @override
  String get boxName => HiveBoxRegistry.boxClosures;

  @override
  BoxClosureModel fromMap(Map<String, dynamic> map) => BoxClosureModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(BoxClosureModel model) => model.toMap();

  @override
  String getId(BoxClosureModel model) => model.id;
}
