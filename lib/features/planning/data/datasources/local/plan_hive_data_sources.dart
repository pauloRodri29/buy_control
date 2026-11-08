import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/planning/data/models/plan_board_model.dart';
import 'package:buy_control/features/planning/data/models/plan_item_model.dart';

class PlanBoardHiveDataSource extends HiveCollectionDataSource<PlanBoardModel> {
  @override
  String get boxName => HiveBoxRegistry.planBoards;

  @override
  PlanBoardModel fromMap(Map<String, dynamic> map) => PlanBoardModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(PlanBoardModel model) => model.toMap();

  @override
  String getId(PlanBoardModel model) => model.id;
}

class PlanItemHiveDataSource extends HiveCollectionDataSource<PlanItemModel> {
  @override
  String get boxName => HiveBoxRegistry.planItems;

  @override
  PlanItemModel fromMap(Map<String, dynamic> map) => PlanItemModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(PlanItemModel model) => model.toMap();

  @override
  String getId(PlanItemModel model) => model.id;
}
