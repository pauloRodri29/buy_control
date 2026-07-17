import 'package:flutter/foundation.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/database/legacy_data_reader.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

const currentSchemaVersion = 2;

/// Migra os dados do formato legado (uma única Hive box com `List<Map>` de
/// "boxes" contendo "produtos" que na prática já eram lançamentos com preço
/// e quantidade) para as entidades novas (`BoxEntity` + `TransactionEntity`).
///
/// Idempotente: reaproveita os ids das boxes legadas e só roda enquanto
/// `schemaVersion < currentSchemaVersion`.
class MigrationRunner {
  final AppMetaStore metaStore;
  final LegacyDataReader legacyDataReader;
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;
  final UnitRepository unitRepository;

  const MigrationRunner({
    required this.metaStore,
    required this.legacyDataReader,
    required this.boxRepository,
    required this.transactionRepository,
    required this.unitRepository,
  });

  Future<void> run() async {
    if (metaStore.schemaVersion >= currentSchemaVersion) return;

    final legacyBoxes = legacyDataReader.readLegacyBoxList();
    if (legacyBoxes.isEmpty) {
      await metaStore.setSchemaVersion(currentSchemaVersion);
      return;
    }

    await legacyDataReader.backupRaw(legacyBoxes);

    final unitsResult = await unitRepository.getAll();
    final units = unitsResult.dataOrNull ?? [];
    final fallbackUnitId = units.isEmpty
        ? null
        : (units.where((u) => u.abbreviation == 'UN').firstOrNull ?? units.first).id;

    String? resolveUnitId(String? legacyUnitType) {
      if (legacyUnitType == null) return fallbackUnitId;
      final match = units.where((u) => u.abbreviation == legacyUnitType).firstOrNull;
      return match?.id ?? fallbackUnitId;
    }

    for (final legacyBox in legacyBoxes) {
      final boxId = legacyBox['id'] as String? ?? IdGenerator.generate();
      final boxName = legacyBox['name'] as String? ?? 'Box migrada';
      final boxCreatedAt = _parseDate(legacyBox['createdAt']) ?? DateTime.now();
      final boxUpdatedAt = _parseDate(legacyBox['updatedAt']) ?? boxCreatedAt;

      await boxRepository.create(BoxEntity(
        id: boxId,
        name: boxName,
        createdAt: boxCreatedAt,
        updatedAt: boxUpdatedAt,
      ));

      final legacyProducts = (legacyBox['products'] as List? ?? [])
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();

      var expectedTotalCents = 0;
      var actualTotalCents = 0;

      for (final legacyProduct in legacyProducts) {
        final name = legacyProduct['name'] as String? ?? 'Item migrado';
        final price = (legacyProduct['price'] as num?)?.toDouble() ?? 0;
        final quantity = (legacyProduct['quantity'] as num?)?.toDouble() ?? 1;
        final unitType = legacyProduct['unitType'] as String?;

        final unitPrice = Money.fromReais(price);
        expectedTotalCents += (unitPrice * quantity).cents;

        final transactionId = IdGenerator.generate();
        final item = TransactionItemEntity(
          id: IdGenerator.generate(),
          transactionId: transactionId,
          nameSnapshot: name,
          unitId: resolveUnitId(unitType) ?? 'UN',
          quantity: quantity,
          unitPrice: unitPrice,
        );

        final transaction = TransactionEntity(
          id: transactionId,
          boxId: boxId,
          title: name,
          occurredAt: boxUpdatedAt,
          items: [item],
          createdAt: boxUpdatedAt,
          updatedAt: boxUpdatedAt,
        );

        actualTotalCents += transaction.total.cents;
        await transactionRepository.create(transaction);
      }

      if (expectedTotalCents != actualTotalCents) {
        debugPrint(
          'Migração: divergência de total na box "$boxName" '
          '(esperado ${expectedTotalCents}c, obtido ${actualTotalCents}c)',
        );
      }
    }

    await metaStore.setSchemaVersion(currentSchemaVersion);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
