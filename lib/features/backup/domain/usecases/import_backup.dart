import 'dart:convert';

import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/box_closures/data/models/box_closure_model.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/models/box_model.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/categories/data/models/category_model.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/product_types/data/models/product_type_model.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/products/data/models/product_model.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/models/transaction_model.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:buy_control/features/units/data/models/unit_model.dart';

/// Restaura um backup gerado por `ExportBackup`, substituindo por completo
/// (não mesclando) os dados de cada um dos 7 boxes do Hive. Substituir em
/// vez de mesclar é a escolha deliberada aqui: mesclar exigiria resolver
/// conflitos de id/versão entre o arquivo e o que já existe localmente, o
/// que é ambíguo e imprevisível; a UI já avisa claramente o usuário antes
/// de disparar essa operação.
class ImportBackup {
  final BoxHiveDataSource boxDataSource;
  final ProductHiveDataSource productDataSource;
  final CategoryHiveDataSource categoryDataSource;
  final ProductTypeHiveDataSource productTypeDataSource;
  final UnitHiveDataSource unitDataSource;
  final TransactionHiveDataSource transactionDataSource;
  final BoxClosureHiveDataSource boxClosureDataSource;

  const ImportBackup({
    required this.boxDataSource,
    required this.productDataSource,
    required this.categoryDataSource,
    required this.productTypeDataSource,
    required this.unitDataSource,
    required this.transactionDataSource,
    required this.boxClosureDataSource,
  });

  Future<Result<void>> call(String jsonString) async {
    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const Failure(ValidationFailure('Arquivo inválido: não é um backup do Buy Control.'));
      }
      data = decoded;
    } catch (_) {
      return const Failure(ValidationFailure('Arquivo inválido: o conteúdo não é um JSON válido.'));
    }

    if (!data.containsKey('version')) {
      return const Failure(ValidationFailure('Arquivo inválido: não é um backup do Buy Control.'));
    }

    try {
      await boxDataSource.clear();
      await boxDataSource.putAll(_listOf(data['boxes']).map(BoxModel.fromMap).toList());

      await productDataSource.clear();
      await productDataSource.putAll(_listOf(data['products']).map(ProductModel.fromMap).toList());

      await categoryDataSource.clear();
      await categoryDataSource.putAll(_listOf(data['categories']).map(CategoryModel.fromMap).toList());

      await productTypeDataSource.clear();
      await productTypeDataSource.putAll(_listOf(data['productTypes']).map(ProductTypeModel.fromMap).toList());

      await unitDataSource.clear();
      await unitDataSource.putAll(_listOf(data['units']).map(UnitModel.fromMap).toList());

      await transactionDataSource.clear();
      await transactionDataSource.putAll(_listOf(data['transactions']).map(TransactionModel.fromMap).toList());

      await boxClosureDataSource.clear();
      await boxClosureDataSource.putAll(_listOf(data['boxClosures']).map(BoxClosureModel.fromMap).toList());

      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure('Falha ao importar o backup. Verifique se o arquivo não está corrompido.'));
    }
  }

  List<Map<String, dynamic>> _listOf(dynamic raw) {
    return ((raw as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
