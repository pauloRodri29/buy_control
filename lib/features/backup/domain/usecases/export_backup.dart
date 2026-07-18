import 'dart:convert';

import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';

/// Versão do formato de backup, embutida no JSON exportado. Bump quando a
/// forma do arquivo mudar de um jeito que `ImportBackup` precise saber
/// distinguir.
const backupFormatVersion = 1;

/// Gera um dump completo dos dados do app (todos os 7 boxes do Hive, via
/// os Models de cada feature) como uma única string JSON, pronta para ser
/// salva em arquivo e compartilhada. Trabalha direto nos data sources (não
/// nos repositórios) porque isso é um dump bruto de armazenamento, não uma
/// operação de negócio — evita ida e volta Model -> Entity -> Model e já
/// inclui registros com soft delete, que os repositórios filtram por padrão.
class ExportBackup {
  final BoxHiveDataSource boxDataSource;
  final ProductHiveDataSource productDataSource;
  final CategoryHiveDataSource categoryDataSource;
  final ProductTypeHiveDataSource productTypeDataSource;
  final UnitHiveDataSource unitDataSource;
  final TransactionHiveDataSource transactionDataSource;
  final BoxClosureHiveDataSource boxClosureDataSource;

  const ExportBackup({
    required this.boxDataSource,
    required this.productDataSource,
    required this.categoryDataSource,
    required this.productTypeDataSource,
    required this.unitDataSource,
    required this.transactionDataSource,
    required this.boxClosureDataSource,
  });

  Future<Result<String>> call() async {
    try {
      final boxes = await boxDataSource.getAll();
      final products = await productDataSource.getAll();
      final categories = await categoryDataSource.getAll();
      final productTypes = await productTypeDataSource.getAll();
      final units = await unitDataSource.getAll();
      final transactions = await transactionDataSource.getAll();
      final boxClosures = await boxClosureDataSource.getAll();

      final payload = {
        'version': backupFormatVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'boxes': boxes.map((m) => m.toMap()).toList(),
        'products': products.map((m) => m.toMap()).toList(),
        'categories': categories.map((m) => m.toMap()).toList(),
        'productTypes': productTypes.map((m) => m.toMap()).toList(),
        'units': units.map((m) => m.toMap()).toList(),
        'transactions': transactions.map((m) => m.toMap()).toList(),
        'boxClosures': boxClosures.map((m) => m.toMap()).toList(),
      };

      return Success(jsonEncode(payload));
    } catch (_) {
      return const Failure(CacheFailure('Falha ao gerar o backup dos dados locais.'));
    }
  }
}
