import 'package:hive_flutter/hive_flutter.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';

/// Acesso somente-leitura ao formato legado de dados (pré Clean Architecture),
/// usado apenas pela migração. Não conhece as entidades novas.
class LegacyDataReader {
  Box get _legacyBox => Hive.box(HiveBoxRegistry.legacyBox);
  Box get _backupBox => Hive.box(HiveBoxRegistry.backupPreMigrationV2);

  List<Map<String, dynamic>> readLegacyBoxList() {
    final raw = _legacyBox.get('boxList');
    if (raw == null || raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> backupRaw(List<Map<String, dynamic>> rawBoxList) async {
    await _backupBox.put('boxList_raw', rawBoxList);
  }
}
