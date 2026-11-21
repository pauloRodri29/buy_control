import 'dart:convert';
import 'dart:io';

import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/data/safety_snapshot_store.dart';
import 'package:buy_control/features/backup/domain/repositories/backup_remote.dart';
import 'package:buy_control/features/backup/domain/usecases/export_backup.dart';
import 'package:buy_control/features/backup/domain/usecases/import_backup.dart';
import 'package:buy_control/features/backup/presentation/controllers/backup_controller.dart';
import 'package:buy_control/features/backup/presentation/pages/backup_preview_page.dart';
import 'package:buy_control/features/box_closures/data/datasources/local/box_closure_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/models/box_model.dart';
import 'package:buy_control/features/categories/data/datasources/local/category_hive_data_source.dart';
import 'package:buy_control/features/planning/data/datasources/local/plan_hive_data_sources.dart';
import 'package:buy_control/features/product_types/data/datasources/local/product_type_hive_data_source.dart';
import 'package:buy_control/features/products/data/datasources/local/product_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

Map<String, dynamic> _box(String id, String name) => {
      'id': id,
      'name': name,
      'isArchived': false,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'deletedAt': null,
      'syncStatus': 'synced',
      'version': 1,
    };

String _backupWith(List<Map<String, dynamic>> boxes) =>
    jsonEncode({'version': 1, 'exportedAt': '2026-01-02T00:00:00.000Z', 'boxes': boxes});

class _FakeRemote implements BackupRemote {
  RemoteBackupFile? latest;
  String? downloadContent;
  AppFailure? uploadFailure;
  String? uploadedContent;
  String? uploadedExpectedSha;

  @override
  Future<Result<RemoteTargetInfo>> testConnection() async => const Success(
      RemoteTargetInfo(displayName: 'joao/backup', webUrl: '', isPrivate: true, defaultBranch: 'main'));

  @override
  Future<Result<RemoteBackupFile?>> fetchLatest() async => Success(latest);

  @override
  Future<Result<RemoteBackupVersion>> upload(String content, {required String message, String? expectedSha}) async {
    if (uploadFailure != null) return Failure(uploadFailure!);
    uploadedContent = content;
    uploadedExpectedSha = expectedSha;
    return Success(RemoteBackupVersion(ref: 'c1', date: DateTime.now(), message: message));
  }

  @override
  Future<Result<List<RemoteBackupVersion>>> history({int limit = 30}) async => const Success([]);

  @override
  Future<Result<String>> download(String ref) async => Success(downloadContent!);
}

void main() {
  late Directory tempDir;
  late _FakeRemote remote;
  late List<BackupPreviewArgs> previews;
  late bool confirmPreview;
  late BackupController controller;
  final boxes = BoxHiveDataSource();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR');
    tempDir = await Directory.systemTemp.createTemp('gastolog_backup_test');
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
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await Hive.box(HiveBoxRegistry.appMeta).clear();
    await boxes.clear();
    await boxes.putAll([BoxModel.fromMap(_box('local', 'Mercado'))]);

    final snapshotDir = await tempDir.createTemp('snap');
    remote = _FakeRemote();
    previews = [];
    confirmPreview = true;

    ExportBackup export() => ExportBackup(
          boxDataSource: boxes,
          productDataSource: ProductHiveDataSource(),
          categoryDataSource: CategoryHiveDataSource(),
          productTypeDataSource: ProductTypeHiveDataSource(),
          unitDataSource: UnitHiveDataSource(),
          transactionDataSource: TransactionHiveDataSource(),
          boxClosureDataSource: BoxClosureHiveDataSource(),
          planBoardDataSource: PlanBoardHiveDataSource(),
          planItemDataSource: PlanItemHiveDataSource(),
        );
    final settings = BackupSettingsStore();
    await settings.saveGithub(const GithubBackupConfig(owner: 'joao', repo: 'backup'), 'tok');

    controller = BackupController(
      exportBackup: export(),
      importBackup: ImportBackup(
        boxDataSource: boxes,
        productDataSource: ProductHiveDataSource(),
        categoryDataSource: CategoryHiveDataSource(),
        productTypeDataSource: ProductTypeHiveDataSource(),
        unitDataSource: UnitHiveDataSource(),
        transactionDataSource: TransactionHiveDataSource(),
        boxClosureDataSource: BoxClosureHiveDataSource(),
        planBoardDataSource: PlanBoardHiveDataSource(),
        planItemDataSource: PlanItemHiveDataSource(),
      ),
      settings: settings,
      safety: SafetySnapshotStore(directory: () async => snapshotDir),
      httpClient: http.Client(),
      remoteFactory: (_, _) => remote,
      openPreview: (args) async {
        previews.add(args);
        return confirmPreview;
      },
    );
    await controller.refreshState();
  });

  Future<List<String>> boxNames() async => (await boxes.getAll()).map((b) => b.name).toList();

  final version = RemoteBackupVersion(ref: 'v1', date: DateTime(2026, 1, 2), message: 'Backup');

  test('restaurar da nuvem mostra o resumo, guarda cópia e substitui', () async {
    remote.downloadContent = _backupWith([_box('cloud', 'Farmácia')]);

    await controller.restoreFromCloud(version);

    final diff = previews.single.diff;
    expect(previews.single.direction, BackupDirection.restore);
    expect(diff.totalAdded, 1);
    expect(diff.totalRemoved, 1);
    expect(await boxNames(), ['Farmácia']);
    expect(controller.safetyInfo, isNotNull);
    expect(controller.log.first.success, isTrue);
    expect(controller.log.first.operation, BackupOperation.restoreCloud);
  });

  test('cancelar no resumo não altera nada nem cria cópia', () async {
    remote.downloadContent = _backupWith([_box('cloud', 'Farmácia')]);
    confirmPreview = false;

    await controller.restoreFromCloud(version);

    expect(await boxNames(), ['Mercado']);
    expect(controller.safetyInfo, isNull);
    expect(controller.log, isEmpty);
  });

  test('desfazer importação volta aos dados anteriores e consome a cópia', () async {
    remote.downloadContent = _backupWith([_box('cloud', 'Farmácia')]);
    await controller.restoreFromCloud(version);

    await controller.undoLastImport();

    expect(previews.last.direction, BackupDirection.undo);
    expect(await boxNames(), ['Mercado']);
    expect(controller.safetyInfo, isNull);
    expect(controller.log.first.operation, BackupOperation.undoImport);
  });

  test('backup inválido falha antes do resumo e registra o erro', () async {
    remote.downloadContent = 'lixo';

    await controller.restoreFromCloud(version);

    expect(previews, isEmpty);
    expect(await boxNames(), ['Mercado']);
    expect(controller.log.first.success, isFalse);
    expect(controller.log.first.message, contains('JSON'));
  });

  test('enviar compara com a nuvem e manda o sha conferido', () async {
    remote.latest = RemoteBackupFile(content: _backupWith([_box('cloud', 'Farmácia')]), sha: 'sha1');

    await controller.uploadNow();

    final args = previews.single;
    expect(args.direction, BackupDirection.upload);
    expect(args.diff.totalAdded, 1); // "Mercado" passa a existir na nuvem
    expect(args.diff.totalRemoved, 1); // "Farmácia" sai do backup mais recente
    expect(remote.uploadedExpectedSha, 'sha1');
    expect(jsonDecode(remote.uploadedContent!)['boxes'][0]['name'], 'Mercado');
    expect(controller.lastSuccessfulUpload, isNotNull);
  });

  test('falha no envio fica registrada como última tentativa', () async {
    remote.uploadFailure = const NetworkFailure('Sem conexão com a internet.');

    await controller.uploadNow();

    expect(controller.lastSuccessfulUpload, isNull);
    expect(controller.lastCloudAttempt?.success, isFalse);
    expect(controller.lastCloudAttempt?.message, 'Sem conexão com a internet.');
    expect(controller.isBusy, isFalse);
  });
}
