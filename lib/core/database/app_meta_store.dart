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

  /// Preferência de tema ("system", "light" ou "dark"). `null` = nunca
  /// escolhida, o app segue o sistema.
  String? get themeMode => _box.get('themeMode') as String?;

  Future<void> setThemeMode(String value) => _box.put('themeMode', value);

  /// Idioma escolhido ("pt_BR" ou "en_US"). `null` = nunca escolhido, o
  /// app segue o idioma do aparelho.
  String? get locale => _box.get('locale') as String?;

  Future<void> setLocale(String value) => _box.put('locale', value);
}
