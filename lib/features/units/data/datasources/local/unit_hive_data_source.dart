import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/units/data/models/unit_model.dart';

class UnitHiveDataSource extends HiveCollectionDataSource<UnitModel> {
  @override
  String get boxName => HiveBoxRegistry.units;

  @override
  UnitModel fromMap(Map<String, dynamic> map) => UnitModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(UnitModel model) => model.toMap();

  @override
  String getId(UnitModel model) => model.id;
}
