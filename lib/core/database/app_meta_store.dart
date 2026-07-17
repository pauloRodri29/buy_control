import 'package:hive_flutter/hive_flutter.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';

/// Metadados internos do app (versão de schema, flags de setup) guardados
/// à parte dos dados de domínio.
class AppMetaStore {
  Box get _box => Hive.box(HiveBoxRegistry.appMeta);

  int get schemaVersion => _box.get('schemaVersion', defaultValue: 0) as int;

  Future<void> setSchemaVersion(int version) => _box.put('schemaVersion', version);

  bool get defaultsSeeded => _box.get('defaultsSeeded', defaultValue: false) as bool;

  Future<void> setDefaultsSeeded(bool value) => _box.put('defaultsSeeded', value);
}
