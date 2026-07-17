import 'package:hive_flutter/hive_flutter.dart';

/// CRUD genérico sobre um Hive box, onde cada registro é salvo como
/// `Map<String, dynamic>` sob a chave do seu próprio id. Cada data source
/// de feature estende esta classe informando o nome do box e como
/// converter entre o Map bruto e o Model da feature.
abstract class HiveCollectionDataSource<M> {
  String get boxName;

  M fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(M model);
  String getId(M model);

  Box get _box => Hive.box(boxName);

  Future<List<M>> getAll() async {
    return _box.values
        .map((raw) => fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<M?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> put(M model) async {
    await _box.put(getId(model), toMap(model));
  }

  Future<void> putAll(List<M> models) async {
    await _box.putAll({for (final m in models) getId(m): toMap(m)});
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
