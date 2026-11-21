import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Informações da cópia de segurança feita antes da última importação.
class SafetySnapshotInfo {
  final DateTime createdAt;

  /// De onde veio o backup que substituiu os dados ("arquivo …",
  /// "nuvem · versão de 21/11/2026 14:30").
  final String replacedBy;

  const SafetySnapshotInfo({required this.createdAt, required this.replacedBy});
}

/// Cópia automática dos dados do aparelho tirada logo antes de qualquer
/// importação/restauração. É o que torna a importação reversível: o botão
/// "Desfazer última importação" restaura esta cópia. Só a última é
/// mantida (cada nova importação sobrescreve).
class SafetySnapshotStore {
  final Future<Directory> Function() _directory;

  SafetySnapshotStore({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory;

  static const _dataFile = 'gastolog_pre_import_snapshot.json';
  static const _infoFile = 'gastolog_pre_import_snapshot.meta.json';

  Future<File> _file(String name) async => File('${(await _directory()).path}/$name');

  Future<void> save(String backupJson, {required String replacedBy}) async {
    await (await _file(_dataFile)).writeAsString(backupJson, flush: true);
    await (await _file(_infoFile)).writeAsString(
      jsonEncode({'createdAt': DateTime.now().toIso8601String(), 'replacedBy': replacedBy}),
      flush: true,
    );
  }

  Future<SafetySnapshotInfo?> info() async {
    try {
      final data = await _file(_dataFile);
      final meta = await _file(_infoFile);
      if (!await data.exists() || !await meta.exists()) return null;
      final map = jsonDecode(await meta.readAsString()) as Map;
      return SafetySnapshotInfo(
        createdAt: DateTime.parse('${map['createdAt']}'),
        replacedBy: '${map['replacedBy']}',
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> read() async {
    final data = await _file(_dataFile);
    return await data.exists() ? data.readAsString() : null;
  }

  Future<void> discard() async {
    for (final name in [_dataFile, _infoFile]) {
      final file = await _file(name);
      if (await file.exists()) await file.delete();
    }
  }
}
