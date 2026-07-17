import 'dart:io';

import 'package:buy_control/app/bootstrap/migration_runner.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/database/legacy_data_reader.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/boxes/data/datasources/local/box_hive_data_source.dart';
import 'package:buy_control/features/boxes/data/repositories/local_box_repository.dart';
import 'package:buy_control/features/transactions/data/datasources/local/transaction_hive_data_source.dart';
import 'package:buy_control/features/transactions/data/repositories/local_transaction_repository.dart';
import 'package:buy_control/features/units/data/datasources/local/unit_hive_data_source.dart';
import 'package:buy_control/features/units/data/repositories/local_unit_repository.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buy_control_migration_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxRegistry.legacyBox);
    await Hive.openBox(HiveBoxRegistry.appMeta);
    await Hive.openBox(HiveBoxRegistry.backupPreMigrationV2);
    await Hive.openBox(HiveBoxRegistry.boxes);
    await Hive.openBox(HiveBoxRegistry.transactions);
    await Hive.openBox(HiveBoxRegistry.units);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('migra dados legados uma vez e é idempotente ao rodar de novo', () async {
    final unitRepository = LocalUnitRepository(localDataSource: UnitHiveDataSource());
    final now = DateTime.now();
    await unitRepository.create(UnitEntity(
      id: IdGenerator.generate(),
      name: 'Unidade',
      abbreviation: 'UN',
      createdAt: now,
      updatedAt: now,
    ));

    final legacyBox = Hive.box(HiveBoxRegistry.legacyBox);
    await legacyBox.put('boxList', [
      {
        'id': 'legacy-box-1',
        'name': 'Mercado',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'products': [
          {
            'id': 'legacy-product-1',
            'name': 'Café',
            'description': null,
            'price': 13.79,
            'quantity': 3,
            'unitType': 'UN',
          },
          {
            'id': 'legacy-product-2',
            'name': 'Leite',
            'description': null,
            'price': 5.5,
            'quantity': 2,
            'unitType': 'UN',
          },
        ],
      },
    ]);

    final boxRepository = LocalBoxRepository(localDataSource: BoxHiveDataSource());
    final transactionRepository = LocalTransactionRepository(localDataSource: TransactionHiveDataSource());
    final metaStore = AppMetaStore();

    final runner = MigrationRunner(
      metaStore: metaStore,
      legacyDataReader: LegacyDataReader(),
      boxRepository: boxRepository,
      transactionRepository: transactionRepository,
      unitRepository: unitRepository,
    );

    await runner.run();

    final boxesAfterFirstRun = (await boxRepository.getAll()).dataOrNull!;
    final transactionsAfterFirstRun = (await transactionRepository.getAll()).dataOrNull!;

    expect(boxesAfterFirstRun.length, 1);
    expect(boxesAfterFirstRun.first.id, 'legacy-box-1');
    expect(transactionsAfterFirstRun.length, 2);

    // 13.79*3 + 5.50*2 = 41.37 + 11.00 = 52.37
    final totalCents = transactionsAfterFirstRun.fold(0, (sum, t) => sum + t.total.cents);
    expect(totalCents, 5237);
    expect(metaStore.schemaVersion, currentSchemaVersion);

    // Rodar de novo não deve duplicar nada (idempotência).
    await runner.run();

    final boxesAfterSecondRun = (await boxRepository.getAll()).dataOrNull!;
    final transactionsAfterSecondRun = (await transactionRepository.getAll()).dataOrNull!;

    expect(boxesAfterSecondRun.length, 1);
    expect(transactionsAfterSecondRun.length, 2);

    final backupBox = Hive.box(HiveBoxRegistry.backupPreMigrationV2);
    expect(backupBox.get('boxList_raw'), isNotNull);
  });
}
