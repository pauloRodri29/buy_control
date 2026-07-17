import 'package:hive_flutter/hive_flutter.dart';

/// Nomes centralizados dos Hive boxes usados pelo app e ponto único de
/// abertura de todos eles, evitando `Hive.openBox` espalhado pelo código.
class HiveBoxRegistry {
  HiveBoxRegistry._();

  static const legacyBox = 'box_buy_control';
  static const appMeta = 'app_meta';
  static const backupPreMigrationV2 = 'backup_pre_migration_v2';

  static const boxes = 'boxes';
  static const products = 'products';
  static const categories = 'categories';
  static const productTypes = 'product_types';
  static const units = 'units';
  static const transactions = 'transactions';

  static const _allBoxNames = [
    legacyBox,
    appMeta,
    backupPreMigrationV2,
    boxes,
    products,
    categories,
    productTypes,
    units,
    transactions,
  ];

  static Future<void> initHive() async {
    await Hive.initFlutter();
    for (final name in _allBoxNames) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox(name);
      }
    }
  }
}
