import 'dart:io';

import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/features/backup/domain/usecases/export_backup.dart';
import 'package:buy_control/features/backup/domain/usecases/import_backup.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Ações de backup completo do app (exportar/importar um dump de todos os
/// dados em um único `.json`). Funções soltas de propósito — é uma
/// operação pontual de arquivo, não uma tela com estado, então não há
/// controller/binding dedicados; a página de Configurações apenas chama
/// `runExportBackup`/`runImportBackup` a partir de um botão.

ExportBackup _buildExportBackup() {
  return ExportBackup(
    boxDataSource: BoxHiveDataSource(),
    productDataSource: ProductHiveDataSource(),
    categoryDataSource: CategoryHiveDataSource(),
    productTypeDataSource: ProductTypeHiveDataSource(),
    unitDataSource: UnitHiveDataSource(),
    transactionDataSource: TransactionHiveDataSource(),
    boxClosureDataSource: BoxClosureHiveDataSource(),
  );
}

ImportBackup _buildImportBackup() {
  return ImportBackup(
    boxDataSource: BoxHiveDataSource(),
    productDataSource: ProductHiveDataSource(),
    categoryDataSource: CategoryHiveDataSource(),
    productTypeDataSource: ProductTypeHiveDataSource(),
    unitDataSource: UnitHiveDataSource(),
    transactionDataSource: TransactionHiveDataSource(),
    boxClosureDataSource: BoxClosureHiveDataSource(),
  );
}

String _timestampForFileName(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}${two(time.second)}';
}

Future<void> runExportBackup(BuildContext context) async {
  final result = await _buildExportBackup()();

  await result.fold(
    (json) async {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'buy_control_backup_${_timestampForFileName(DateTime.now())}.json';
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(json);
        await Share.shareXFiles([XFile(file.path)], text: 'Backup Buy Control');
        Get.snackbar('Backup exportado', 'Arquivo gerado: ${file.path}');
      } catch (_) {
        Get.snackbar('Erro', 'Não foi possível salvar ou compartilhar o arquivo de backup.');
      }
    },
    (failure) async => Get.snackbar('Erro ao exportar', FailurePresenter.present(failure)),
  );
}

Future<void> runImportBackup(BuildContext context) async {
  final confirmed = await ConfirmDialog.show(
    context,
    title: 'Importar backup',
    message:
        'Importar um backup substitui TODOS os dados atuais do app (boxes, produtos, categorias, '
        'tipos, unidades, lançamentos e fechamentos) pelos dados do arquivo escolhido. '
        'Essa ação não pode ser desfeita.',
    confirmLabel: 'Importar e substituir',
  );
  if (!confirmed) return;

  final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
  if (picked == null || picked.files.isEmpty) return;
  final path = picked.files.first.path;
  if (path == null) return;

  try {
    final jsonString = await File(path).readAsString();
    final result = await _buildImportBackup()(jsonString);
    result.fold(
      // Não há um mecanismo de refresh global após o import: recomenda-se
      // reiniciar o app para garantir que todas as telas (que já leram
      // dados antigos em memória) reflitam o backup restaurado. Navegar
      // entre as abas do shell principal já atualiza a maior parte na
      // prática, mas reiniciar é a garantia completa.
      (_) => Get.snackbar(
        'Backup importado',
        'Dados restaurados com sucesso. Recomenda-se reiniciar o app para ver tudo atualizado.',
      ),
      (failure) => Get.snackbar('Erro ao importar', FailurePresenter.present(failure)),
    );
  } catch (_) {
    Get.snackbar('Erro', 'Não foi possível ler o arquivo selecionado.');
  }
}
