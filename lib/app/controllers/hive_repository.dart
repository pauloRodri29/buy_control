import 'package:hive_flutter/hive_flutter.dart';

class HiveRepository {
  final Box _defaultBox = Hive.box('box_buy_control');

  /// Abre ou retorna um box existente
  Future<Box> _resolveBox(String? boxName) async {
    if (boxName == null) return _defaultBox;

    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  ////Pegar o nome da box
  String getBoxName() => _defaultBox.name;

  /// Salvar ou atualizar um valor
  Future<void> save<T>({
    String? boxName,
    required String key,
    required T value,
  }) async {
    final box = await _resolveBox(boxName);
    await box.put(key, value);
  }

  /// Buscar um valor, com valor padrão caso não exista
  Future<T?> get<T>({
    String? boxName,
    required String key,
    T? defaultValue,
  }) async {
    final box = await _resolveBox(boxName);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Deletar um item específico
  Future<void> delete({String? boxName, required String key}) async {
    final box = await _resolveBox(boxName);
    await box.delete(key);
  }

  /// Limpar todo o box
  Future<void> clear(String? boxName) async {
    final box = await _resolveBox(boxName);
    await box.clear();
  }

  /// Verifica se existe uma chave no box
  Future<bool> exists({String? boxName, required String key}) async {
    final box = await _resolveBox(boxName);
    return box.containsKey(key);
  }

  /// Retorna todos os dados de um box específico ou de uma chave específica
  /// Se [key] for fornecida, retorna apenas o valor dessa chave
  /// Se [boxName] for null, usa o box padrão
  Future<Map<String, dynamic>> getBoxData({
    String? boxName,
    String? key,
  }) async {
    final box = await _resolveBox(boxName);

    if (key != null) {
      // Retorna apenas a chave especificada
      if (box.containsKey(key)) {
        return {key: box.get(key)};
      }
      return {};
    }

    // Retorna todos os dados do box
    final Map<String, dynamic> allData = {};
    for (var boxKey in box.keys) {
      allData[boxKey.toString()] = box.get(boxKey);
    }
    return allData;
  }

}
