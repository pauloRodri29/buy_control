import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/transactions/data/models/transaction_model.dart';

class TransactionHiveDataSource extends HiveCollectionDataSource<TransactionModel> {
  @override
  String get boxName => HiveBoxRegistry.transactions;

  @override
  TransactionModel fromMap(Map<String, dynamic> map) => TransactionModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(TransactionModel model) => model.toMap();

  @override
  String getId(TransactionModel model) => model.id;
}
