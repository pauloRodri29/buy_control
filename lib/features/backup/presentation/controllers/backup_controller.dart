import 'dart:io';

import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/data/github_backup_remote.dart';
import 'package:buy_control/features/backup/data/safety_snapshot_store.dart';
import 'package:buy_control/features/backup/domain/entities/backup_collections.dart';
import 'package:buy_control/features/backup/domain/entities/backup_diff.dart';
import 'package:buy_control/features/backup/domain/entities/backup_snapshot.dart';
import 'package:buy_control/features/backup/domain/repositories/backup_remote.dart';
import 'package:buy_control/features/backup/domain/usecases/export_backup.dart';
import 'package:buy_control/features/backup/domain/usecases/import_backup.dart';
import 'package:buy_control/features/backup/presentation/pages/backup_preview_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef BackupRemoteFactory = BackupRemote Function(GithubBackupConfig config, String token);

/// Orquestra o backup (arquivo e nuvem). Toda operação que muda dados
/// segue o mesmo roteiro: ler → comparar ([BackupDiff]) → mostrar o
/// resumo ([BackupPreviewPage]) → só então agir. Importações guardam antes
/// uma cópia de segurança ([SafetySnapshotStore]) e, se falharem no meio,
/// voltam sozinhas ao estado anterior.
class BackupController extends GetxController {
  final ExportBackup exportBackup;
  final ImportBackup importBackup;
  final BackupSettingsStore settings;
  final SafetySnapshotStore safety;
  final http.Client httpClient;
  late final BackupRemoteFactory _remoteFactory;

  /// Abre o resumo e devolve se o usuário confirmou. Substituível em teste.
  final Future<bool> Function(BackupPreviewArgs args) openPreview;

  BackupController({
    required this.exportBackup,
    required this.importBackup,
    required this.settings,
    required this.safety,
    required this.httpClient,
    BackupRemoteFactory? remoteFactory,
    Future<bool> Function(BackupPreviewArgs args)? openPreview,
  }) : openPreview = openPreview ?? BackupPreviewPage.open {
    _remoteFactory = remoteFactory ??
        (config, token) => GithubBackupRemote(config: config, token: token, client: httpClient);
  }

  GithubBackupConfig? config;
  List<BackupLogEntry> log = const [];
  SafetySnapshotInfo? safetyInfo;

  /// Texto da operação em andamento; `null` = livre.
  String? busyMessage;
  bool get isBusy => busyMessage != null;

  @override
  void onInit() {
    super.onInit();
    refreshState();
  }

  @override
  void onClose() {
    httpClient.close();
    super.onClose();
  }

  Future<void> refreshState() async {
    config = settings.githubConfig;
    log = settings.log;
    safetyInfo = await safety.info();
    update();
  }

  bool get isCloudConfigured => config != null;

  BackupLogEntry? get lastSuccessfulUpload =>
      log.firstWhereOrNull((e) => e.operation == BackupOperation.uploadCloud && e.success);

  /// Última tentativa com a nuvem (envio ou restauração), com sucesso ou não.
  BackupLogEntry? get lastCloudAttempt => log.firstWhereOrNull(
        (e) => e.operation == BackupOperation.uploadCloud || e.operation == BackupOperation.restoreCloud,
      );

  void _setBusy(String? message) {
    busyMessage = message;
    update();
  }

  Future<void> _record(BackupOperation operation, {required bool success, required String message}) async {
    await settings.addLog(BackupLogEntry(at: DateTime.now(), operation: operation, success: success, message: message));
    log = settings.log;
    update();
  }

  Future<void> _fail(BackupOperation operation, AppFailure failure) async {
    await _record(operation, success: false, message: failure.message.tr);
    FailurePresenter.show(failure, title: 'backup.failedName'.trParams({'toLowerCase': operation.label.toLowerCase()}));
  }

  // ---------------------------------------------------------------- GitHub

  Future<Result<RemoteTargetInfo>> testGithub(GithubBackupConfig config, String token) {
    return _remoteFactory(config, token).testConnection();
  }

  /// Testa e, se der certo, salva. Devolve o resultado do teste.
  Future<Result<RemoteTargetInfo>> saveGithub(GithubBackupConfig config, String token) async {
    final result = await testGithub(config, token);
    if (result.isSuccess) {
      await settings.saveGithub(config, token);
      await refreshState();
    }
    return result;
  }

  Future<void> disconnectGithub() async {
    await settings.clearGithub();
    await refreshState();
  }

  Future<Result<BackupRemote>> _remote() async {
    final current = config;
    if (current == null) {
      return Failure(ValidationFailure('backup.setUpGithubRepositoryBefore'.tr));
    }
    final token = await settings.readToken();
    if (token == null || token.isEmpty) {
      return Failure(ValidationFailure('backup.githubTokenWasNotFound'.tr));
    }
    return Success(_remoteFactory(current, token));
  }

  Future<Result<List<RemoteBackupVersion>>> loadHistory() async {
    final remote = await _remote();
    return remote.fold((r) => r.history(), Failure.new);
  }

  /// Envia os dados do aparelho para o GitHub, depois de mostrar o que
  /// muda em relação ao backup que já está lá.
  Future<void> uploadNow() async {
    if (isBusy) return;
    const op = BackupOperation.uploadCloud;
    try {
      _setBusy('backup.checkingBackupCloud'.tr);
      final remoteResult = await _remote();
      final remote = remoteResult.dataOrNull;
      if (remote == null) return _fail(op, remoteResult.failureOrNull!);

      final localResult = await exportBackup();
      final localJson = localResult.dataOrNull;
      if (localJson == null) return _fail(op, localResult.failureOrNull!);
      final localSnapshot = BackupSnapshot.parse(localJson).dataOrNull!;

      final latestResult = await remote.fetchLatest();
      if (latestResult.isFailure) return _fail(op, latestResult.failureOrNull!);
      final latest = latestResult.dataOrNull;

      final notes = <String>[];
      var remoteSnapshot = _emptySnapshot;
      if (latest == null) {
        notes.add('backup.theresNoBackupRepositoryYet'.tr);
      } else {
        final parsed = BackupSnapshot.parse(latest.content);
        if (parsed.isSuccess) {
          remoteSnapshot = parsed.dataOrNull!;
        } else {
          notes.add('backup.fileCloudNotValidBackup'.tr);
        }
      }
      _setBusy(null);

      final confirmed = await openPreview(BackupPreviewArgs(
        direction: BackupDirection.upload,
        diff: BackupDiff.compare(remoteSnapshot, localSnapshot),
        sourceTitle: 'backup.deviceFullName'.trParams({'fullName': config!.fullName}),
        sourceSubtitle: latest == null
            ? 'backup.firstBackupCloud'.tr
            : 'backup.cloudNowBackupFromFormatdateDate'.trParams({'_formatDate': _formatDate(remoteSnapshot.exportedAt)}),
        notes: notes,
      ));
      if (!confirmed) return;

      _setBusy('backup.sendingGithub'.tr);
      final upload = await remote.upload(
        localJson,
        message: _commitMessage(localSnapshot),
        expectedSha: latest?.sha,
      );
      await upload.fold(
        (_) async {
          final message = 'backup.sentRecordsFullNameTotalActive'.trParams({'fullName': config!.fullName, 'totalActive': '${localSnapshot.totalActive}'});
          await _record(op, success: true, message: message);
          AppFeedback.success(message, title: 'backup.backupSent'.tr);
        },
        (failure) => _fail(op, failure),
      );
    } finally {
      _setBusy(null);
    }
  }

  Future<void> restoreFromCloud(RemoteBackupVersion version) async {
    if (isBusy) return;
    const op = BackupOperation.restoreCloud;
    String? json;
    try {
      _setBusy('backup.downloadingBackup'.tr);
      final remoteResult = await _remote();
      final remote = remoteResult.dataOrNull;
      if (remote == null) return _fail(op, remoteResult.failureOrNull!);
      final download = await remote.download(version.ref);
      json = download.dataOrNull;
      if (json == null) return _fail(op, download.failureOrNull!);
    } finally {
      _setBusy(null);
    }
    await _restore(
      json,
      operation: op,
      sourceTitle: 'backup.cloudFullName'.trParams({'fullName': config!.fullName}),
      sourceLabel: 'backup.cloudVersionFromDateTime'.trParams({'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(version.date)}),
    );
  }

  // --------------------------------------------------------------- Arquivo

  Future<void> exportToFile() async {
    if (isBusy) return;
    const op = BackupOperation.exportFile;
    try {
      _setBusy('backup.generatingFile'.tr);
      final result = await exportBackup();
      final json = result.dataOrNull;
      if (json == null) return _fail(op, result.failureOrNull!);

      final snapshot = BackupSnapshot.parse(json).dataOrNull!;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/gastolog_backup_${_timestampForFileName(DateTime.now())}.json');
      await file.writeAsString(json);
      _setBusy(null);
      await Share.shareXFiles([XFile(file.path)], text: 'backup.backupName'.trParams({'name': AppBrand.name}));
      final message = 'backup.fileGeneratedRecordsFormatsizeTotalActiveSize'.trParams({'totalActive': '${snapshot.totalActive}', '_formatSize': _formatSize(snapshot.sizeInBytes)});
      await _record(op, success: true, message: message);
      AppFeedback.success(message, title: 'backup.backupExported'.tr);
    } catch (_) {
      await _fail(op, CacheFailure('backup.couldntSaveShareBackupFile'.tr));
    } finally {
      _setBusy(null);
    }
  }

  Future<void> importFromFile() async {
    if (isBusy) return;
    const op = BackupOperation.importFile;
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    final file = picked?.files.firstOrNull;
    if (file?.path == null) return;

    final String json;
    try {
      json = await File(file!.path!).readAsString();
    } catch (_) {
      return _fail(op, CacheFailure('backup.couldntReadSelectedFile'.tr));
    }
    await _restore(json, operation: op, sourceTitle: 'backup.fileName'.trParams({'name': file.name}), sourceLabel: 'backup.fileNameLower'.trParams({'name': file.name}));
  }

  // ------------------------------------------------------------- Segurança

  Future<void> undoLastImport() async {
    if (isBusy) return;
    final info = safetyInfo;
    final json = await safety.read();
    if (info == null || json == null) {
      return _fail(BackupOperation.undoImport, NotFoundFailure('backup.theresNoImportUndo'.tr));
    }
    await _restore(
      json,
      operation: BackupOperation.undoImport,
      sourceTitle: 'backup.safetyCopy'.tr,
      sourceLabel: 'backup.safetyCopyLower'.tr,
      sourceSubtitle: 'backup.dataWasBeforeImportingDateTimeReplacedBy'.trParams({'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(info.createdAt), 'replacedBy': info.replacedBy}),
      isUndo: true,
    );
  }

  /// Fluxo comum de restauração: valida, compara com o aparelho, mostra o
  /// resumo, guarda a cópia de segurança e só então substitui.
  Future<void> _restore(
    String incomingJson, {
    required BackupOperation operation,
    required String sourceTitle,
    required String sourceLabel,
    String? sourceSubtitle,
    bool isUndo = false,
  }) async {
    String? localJson;
    try {
      _setBusy('backup.comparingDataDevice'.tr);
      final incoming = BackupSnapshot.parse(incomingJson);
      final incomingSnapshot = incoming.dataOrNull;
      if (incomingSnapshot == null) return _fail(operation, incoming.failureOrNull!);

      final localResult = await exportBackup();
      localJson = localResult.dataOrNull;
      if (localJson == null) return _fail(operation, localResult.failureOrNull!);
      final localSnapshot = BackupSnapshot.parse(localJson).dataOrNull!;
      _setBusy(null);

      final confirmed = await openPreview(BackupPreviewArgs(
        direction: isUndo ? BackupDirection.undo : BackupDirection.restore,
        diff: BackupDiff.compare(localSnapshot, incomingSnapshot),
        sourceTitle: sourceTitle,
        sourceSubtitle: sourceSubtitle ?? 'backup.backupCreatedFormatdateDate'.trParams({'_formatDate': _formatDate(incomingSnapshot.exportedAt)}),
      ));
      if (!confirmed) return;

      // Desfazer não gera nova cópia: a cópia atual é consumida.
      if (!isUndo) {
        _setBusy('backup.savingSafetyCopyCurrentData'.tr);
        try {
          await safety.save(localJson, replacedBy: sourceLabel);
        } catch (_) {
          return _fail(operation, CacheFailure(
            'backup.couldntSaveSafetyCopySo'.tr,
          ));
        }
      }

      _setBusy('backup.restoringData'.tr);
      final result = await importBackup(incomingJson);
      if (result.isFailure) {
        // Importação pode ter parado no meio: volta ao estado anterior.
        final rollback = await importBackup(localJson);
        final message = rollback.isSuccess
            ? 'backup.previousDataWasRestoredAutomaticallyMessage'.trParams({'message': result.failureOrNull!.message.tr})
            : 'backup.useUndoLastImportRecoverMessage'.trParams({'message': result.failureOrNull!.message.tr});
        return _fail(operation, CacheFailure(message));
      }

      if (isUndo) await safety.discard();
      final message = isUndo
          ? 'backup.dataWentBackStateBeforeTotalActive'.trParams({'totalActive': '${localSnapshot.totalActive}', 'vBTotalActive': '${incomingSnapshot.totalActive}'})
          : 'backup.restoredFromRecordsSourceLabelTotalActive'.trParams({'sourceLabel': sourceLabel, 'totalActive': '${incomingSnapshot.totalActive}'});
      await _record(operation, success: true, message: message);
      // Não há refresh global após o import: telas que já leram dados
      // antigos podem precisar ser reabertas; reiniciar garante tudo.
      AppFeedback.success('backup.restartingAppRecommendedSeeEverythingMessage'.trParams({'message': message}),
          title: isUndo ? 'backup.importUndone'.tr : 'backup.dataRestored'.tr);
    } finally {
      safetyInfo = await safety.info();
      _setBusy(null);
    }
  }

  // ------------------------------------------------------------ Auxiliares

  static const _emptySnapshot = BackupSnapshot(version: 0, exportedAt: null, collections: {}, sizeInBytes: 0);

  String _commitMessage(BackupSnapshot snapshot) {
    final lines = [
      for (final c in backupCollections)
        if (snapshot.activeCount(c.key) > 0) '${c.label}: ${snapshot.activeCount(c.key)}',
    ];
    return [
      'backup.backupNameDateTime'.trParams({'name': AppBrand.name, 'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(DateTime.now())}),
      '',
      ...lines,
      'backup.totalRecordsFormatsizeTotalActiveSize'.trParams({'totalActive': '${snapshot.totalActive}', '_formatSize': _formatSize(snapshot.sizeInBytes)}),
    ].join('\n');
  }

  static String _formatDate(DateTime? date) => date == null ? 'backup.unknownDate'.tr : DateTimeFormatter.ddMMyyyyHHmm(date);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _timestampForFileName(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
