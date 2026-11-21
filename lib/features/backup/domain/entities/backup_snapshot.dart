import 'package:get/get.dart';
import 'dart:convert';

import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/backup/domain/entities/backup_collections.dart';

/// Leitura validada de um JSON de backup, sem tocar no banco. É a base do
/// resumo mostrado antes de importar ou enviar: dá para saber quando o
/// backup foi gerado e quantos registros de cada tipo ele tem.
class BackupSnapshot {
  final int version;
  final DateTime? exportedAt;

  /// Registros por chave de coleção. A chave fica de fora quando o JSON
  /// não a tem (backup antigo) — diferente de uma lista vazia.
  final Map<String, List<Map<String, dynamic>>> collections;

  /// Tamanho do JSON original, em bytes.
  final int sizeInBytes;

  const BackupSnapshot({
    required this.version,
    required this.exportedAt,
    required this.collections,
    required this.sizeInBytes,
  });

  static Result<BackupSnapshot> parse(String jsonString) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      return Failure(ValidationFailure('backup.invalidFileContentNotValid'.tr));
    }
    if (decoded is! Map || !decoded.containsKey('version')) {
      return Failure(ValidationFailure('backup.invalidFileNotGastologBackup'.tr));
    }

    try {
      final collections = <String, List<Map<String, dynamic>>>{};
      for (final collection in backupCollections) {
        if (!decoded.containsKey(collection.key)) continue;
        final raw = decoded[collection.key];
        collections[collection.key] = ((raw as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return Success(BackupSnapshot(
        version: (decoded['version'] as num).toInt(),
        exportedAt: DateTime.tryParse('${decoded['exportedAt']}')?.toLocal(),
        collections: collections,
        sizeInBytes: utf8.encode(jsonString).length,
      ));
    } catch (_) {
      return Failure(ValidationFailure('backup.invalidFileBackupStructureCorrupted'.tr));
    }
  }

  bool includes(String key) => collections.containsKey(key);

  /// Registros ativos (sem exclusão lógica) de uma coleção.
  List<Map<String, dynamic>> active(String key) =>
      (collections[key] ?? const []).where((r) => r['deletedAt'] == null).toList();

  int activeCount(String key) => active(key).length;

  int get totalActive => backupCollections.fold(0, (sum, c) => sum + activeCount(c.key));

  /// Resumo curto: "3 boxes · 120 lançamentos · 40 produtos".
  String shortSummary() {
    final parts = [
      for (final c in backupCollections)
        if (activeCount(c.key) > 0) '${activeCount(c.key)} ${c.label.toLowerCase()}',
    ];
    return parts.isEmpty ? 'backup.noRecords'.tr : parts.take(4).join(' · ');
  }
}
