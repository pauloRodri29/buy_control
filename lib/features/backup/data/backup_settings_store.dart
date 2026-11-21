import 'package:get/get.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repositório do GitHub onde os backups são gravados. O token NÃO fica
/// aqui (ver [BackupSettingsStore.readToken]).
class GithubBackupConfig {
  final String owner;
  final String repo;

  /// Caminho do arquivo dentro do repositório. Cada envio sobrescreve o
  /// arquivo e vira um commit, que é o histórico de backups.
  final String path;

  const GithubBackupConfig({required this.owner, required this.repo, this.path = defaultPath});

  static const defaultPath = 'gastolog-backup.json';

  String get fullName => '$owner/$repo';

  /// Aceita "dono/repo", "https://github.com/dono/repo" (com ou sem `.git`
  /// e barra final) ou "github.com/dono/repo". `null` se não reconhecer.
  static GithubBackupConfig? parseRepository(String input) {
    var text = input.trim();
    text = text.replaceFirst(RegExp(r'^(https?://)?(www\.)?github\.com/', caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'\.git$'), '').replaceFirst(RegExp(r'/+$'), '');
    final match = RegExp(r'^([A-Za-z0-9-]+)/([A-Za-z0-9._-]+)$').firstMatch(text);
    if (match == null) return null;
    return GithubBackupConfig(owner: match.group(1)!, repo: match.group(2)!);
  }
}

enum BackupOperation { uploadCloud, restoreCloud, exportFile, importFile, undoImport }

extension BackupOperationLabel on BackupOperation {
  String get label => switch (this) {
        BackupOperation.uploadCloud => 'backup.cloudUpload'.tr,
        BackupOperation.restoreCloud => 'backup.cloudRestore'.tr,
        BackupOperation.exportFile => 'backup.exportFile2'.tr,
        BackupOperation.importFile => 'backup.fileImport'.tr,
        BackupOperation.undoImport => 'backup.undoImport'.tr,
      };
}

/// Uma linha do registro de atividade de backup (sucesso ou erro).
class BackupLogEntry {
  final DateTime at;
  final BackupOperation operation;
  final bool success;
  final String message;

  const BackupLogEntry({required this.at, required this.operation, required this.success, required this.message});

  Map<String, dynamic> toMap() => {
        'at': at.toIso8601String(),
        'operation': operation.name,
        'success': success,
        'message': message,
      };

  static BackupLogEntry? fromMap(Map<dynamic, dynamic> map) {
    final at = DateTime.tryParse('${map['at']}');
    final operation = BackupOperation.values.where((o) => o.name == map['operation']).firstOrNull;
    if (at == null || operation == null) return null;
    return BackupLogEntry(
      at: at,
      operation: operation,
      success: map['success'] == true,
      message: '${map['message'] ?? ''}',
    );
  }
}

/// Preferências do backup na nuvem e registro das últimas operações,
/// guardados no box `app_meta`. O token do GitHub vai para o armazenamento
/// seguro do sistema (Keystore/Keychain), nunca para o Hive.
class BackupSettingsStore {
  final FlutterSecureStorage _secure;

  BackupSettingsStore({FlutterSecureStorage? secure}) : _secure = secure ?? const FlutterSecureStorage();

  static const _ownerKey = 'backup.github.owner';
  static const _repoKey = 'backup.github.repo';
  static const _pathKey = 'backup.github.path';
  static const _logKey = 'backup.log';
  static const _tokenKey = 'backup.github.token';
  static const _maxLogEntries = 30;

  Box get _box => Hive.box(HiveBoxRegistry.appMeta);

  GithubBackupConfig? get githubConfig {
    final owner = _box.get(_ownerKey) as String?;
    final repo = _box.get(_repoKey) as String?;
    if (owner == null || repo == null) return null;
    return GithubBackupConfig(
      owner: owner,
      repo: repo,
      path: (_box.get(_pathKey) as String?) ?? GithubBackupConfig.defaultPath,
    );
  }

  Future<String?> readToken() => _secure.read(key: _tokenKey);

  Future<void> saveGithub(GithubBackupConfig config, String token) async {
    await _secure.write(key: _tokenKey, value: token);
    await _box.put(_ownerKey, config.owner);
    await _box.put(_repoKey, config.repo);
    await _box.put(_pathKey, config.path);
  }

  Future<void> clearGithub() async {
    await _secure.delete(key: _tokenKey);
    await _box.delete(_ownerKey);
    await _box.delete(_repoKey);
    await _box.delete(_pathKey);
  }

  /// Registro mais recente primeiro.
  List<BackupLogEntry> get log {
    final raw = (_box.get(_logKey) as List?) ?? const [];
    return raw.whereType<Map>().map(BackupLogEntry.fromMap).whereType<BackupLogEntry>().toList();
  }

  Future<void> addLog(BackupLogEntry entry) async {
    final entries = [entry, ...log].take(_maxLogEntries).map((e) => e.toMap()).toList();
    await _box.put(_logKey, entries);
  }
}
