import 'dart:convert';
import 'dart:io';

import 'package:buy_control/app/theme/app_theme.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/data/safety_snapshot_store.dart';
import 'package:buy_control/features/backup/domain/entities/backup_diff.dart';
import 'package:buy_control/features/backup/domain/entities/backup_snapshot.dart';
import 'package:buy_control/features/backup/domain/usecases/export_backup.dart';
import 'package:buy_control/features/backup/domain/usecases/import_backup.dart';
import 'package:buy_control/features/backup/presentation/controllers/backup_controller.dart';
import 'package:buy_control/features/backup/presentation/pages/backup_page.dart';
import 'package:buy_control/features/backup/presentation/pages/backup_preview_page.dart';
import 'package:buy_control/features/backup/presentation/pages/github_settings_page.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/planning/data/datasources/local/plan_hive_data_sources.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

Map<String, dynamic> _box(String id, String name, String updatedAt) => {
      'id': id,
      'name': name,
      'isArchived': false,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': updatedAt,
      'deletedAt': null,
      'syncStatus': 'synced',
      'version': 1,
    };

BackupSnapshot _snap(List<Map<String, dynamic>> boxes, String exportedAt) =>
    BackupSnapshot.parse(jsonEncode({'version': 1, 'exportedAt': exportedAt, 'boxes': boxes})).dataOrNull!;

/// Telas de backup abrem sem exceção de layout num celular, nos dois temas,
/// com os estados mais "cheios" (erro, cópia de segurança, avisos).
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    tempDir = await Directory.systemTemp.createTemp('gastolog_backup_screens');
    Hive.init(tempDir.path);
    for (final name in [
      HiveBoxRegistry.appMeta,
      HiveBoxRegistry.boxes,
      HiveBoxRegistry.products,
      HiveBoxRegistry.categories,
      HiveBoxRegistry.productTypes,
      HiveBoxRegistry.units,
      HiveBoxRegistry.transactions,
      HiveBoxRegistry.boxClosures,
      HiveBoxRegistry.planBoards,
      HiveBoxRegistry.planItems,
    ]) {
      await Hive.openBox(name);
    }
    FlutterSecureStorage.setMockInitialValues({});
    Get.testMode = true;

    final settings = BackupSettingsStore();
    await settings.saveGithub(const GithubBackupConfig(owner: 'joao-com-nome-longo', repo: 'gastolog-backup-pessoal'), 't');
    await settings.addLog(BackupLogEntry(
      at: DateTime(2026, 11, 20, 9),
      operation: BackupOperation.uploadCloud,
      success: true,
      message: 'Enviado para joao/backup · 120 registros',
    ));
    await settings.addLog(BackupLogEntry(
      at: DateTime(2026, 11, 21, 9),
      operation: BackupOperation.uploadCloud,
      success: false,
      message: 'O GitHub recusou o token (inválido, revogado ou expirado). Gere um novo token e salve nas configurações.',
    ));
    final snapshotDir = await tempDir.createTemp('snap');
    final safety = SafetySnapshotStore(directory: () async => snapshotDir);
    await safety.save('{"version":1}', replacedBy: 'arquivo gastolog_backup_20261121_101010.json');

    final export = ExportBackup(
      boxDataSource: BoxHiveDataSource(),
      productDataSource: ProductHiveDataSource(),
      categoryDataSource: CategoryHiveDataSource(),
      productTypeDataSource: ProductTypeHiveDataSource(),
      unitDataSource: UnitHiveDataSource(),
      transactionDataSource: TransactionHiveDataSource(),
      boxClosureDataSource: BoxClosureHiveDataSource(),
      planBoardDataSource: PlanBoardHiveDataSource(),
      planItemDataSource: PlanItemHiveDataSource(),
    );
    final import = ImportBackup(
      boxDataSource: BoxHiveDataSource(),
      productDataSource: ProductHiveDataSource(),
      categoryDataSource: CategoryHiveDataSource(),
      productTypeDataSource: ProductTypeHiveDataSource(),
      unitDataSource: UnitHiveDataSource(),
      transactionDataSource: TransactionHiveDataSource(),
      boxClosureDataSource: BoxClosureHiveDataSource(),
      planBoardDataSource: PlanBoardHiveDataSource(),
      planItemDataSource: PlanItemHiveDataSource(),
    );
    final controller = BackupController(
      exportBackup: export,
      importBackup: import,
      settings: settings,
      safety: safety,
      httpClient: http.Client(),
    );
    Get.put(controller);
    await controller.refreshState();
  });

  tearDownAll(() async {
    Get.reset();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final diff = BackupDiff.compare(
    _snap([
      _box('a', 'Mercado', '2026-06-01T00:00:00.000Z'),
      _box('b', 'Farmácia com um nome realmente muito comprido para quebrar linha', '2026-01-01T00:00:00.000Z'),
    ], '2026-06-01T00:00:00.000Z'),
    _snap([
      _box('a', 'Mercado antigo', '2026-01-01T00:00:00.000Z'),
      _box('c', 'Pet', '2026-01-01T00:00:00.000Z'),
    ], '2026-02-01T00:00:00.000Z'),
  );

  final pages = <String, Widget Function()>{
    'Backup e restauração': () => const BackupPage(),
    'Backup no GitHub': () => const GithubSettingsPage(),
    'Conferir antes de restaurar': () => BackupPreviewPage(
          args: BackupPreviewArgs(
            direction: BackupDirection.restore,
            diff: diff,
            sourceTitle: 'Nuvem · joao-com-nome-longo/gastolog-backup-pessoal',
            sourceSubtitle: 'Backup gerado em 01/02/2026 00:00',
          ),
        ),
    'Conferir antes de enviar': () => BackupPreviewPage(
          args: BackupPreviewArgs(
            direction: BackupDirection.upload,
            diff: diff,
            sourceTitle: 'Neste aparelho → joao/backup',
            sourceSubtitle: 'Na nuvem agora: backup de 01/02/2026 00:00',
            notes: const ['Ainda não há backup neste repositório: este será o primeiro.'],
          ),
        ),
  };

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final MapEntry(key: title, value: page) in pages.entries) {
      testWidgets('$title abre sem erros no tema ${mode.name}', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          scaffoldMessengerKey: appScaffoldMessengerKey,
          home: page(),
        ));
        await tester.pump(const Duration(milliseconds: 300));

        // Expande os detalhes por tipo, quando houver.
        final expandable = find.byType(ExpansionTile);
        if (expandable.evaluate().isNotEmpty) {
          await tester.ensureVisible(expandable.first);
          await tester.tap(expandable.first);
          await tester.pump(const Duration(milliseconds: 400));
        }

        expect(tester.takeException(), isNull);
        expect(find.text(title), findsWidgets);
      });
    }
  }
}
