import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/storage/hive_collection_data_source.dart';
import 'package:buy_control/features/reports/presentation/controllers/report_filter_state.dart';
import 'package:buy_control/features/reports/presentation/controllers/saved_filter_preset.dart';
import 'package:flutter/material.dart';

/// Persiste as combinações de filtros salvas pelo usuário (`SavedFilterPreset`)
/// no Hive, uma por chave `name`. Reaproveita o CRUD genérico de
/// `HiveCollectionDataSource` (getAll/clear já vêm prontos) e adiciona
/// apenas os apelidos `save`/`remove` esperados pelo `ReportsController`.
class ReportPresetRepository extends HiveCollectionDataSource<SavedFilterPreset> {
  @override
  String get boxName => HiveBoxRegistry.reportPresets;

  @override
  SavedFilterPreset fromMap(Map<String, dynamic> map) {
    return SavedFilterPreset(
      name: map['name'] as String,
      filter: _filterFromMap(Map<String, dynamic>.from(map['filter'] as Map)),
    );
  }

  @override
  Map<String, dynamic> toMap(SavedFilterPreset preset) {
    return {
      'name': preset.name,
      'filter': _filterToMap(preset.filter),
    };
  }

  @override
  String getId(SavedFilterPreset model) => model.name;

  Future<void> save(SavedFilterPreset preset) => put(preset);

  Future<void> remove(String name) => delete(name);

  Map<String, dynamic> _filterToMap(ReportFilterState filter) {
    return {
      'periodPreset': filter.periodPreset.name,
      'customRangeStart': filter.customRange?.start.toIso8601String(),
      'customRangeEnd': filter.customRange?.end.toIso8601String(),
      'boxIds': filter.boxIds.toList(),
      'categoryIds': filter.categoryIds.toList(),
      'productTypeIds': filter.productTypeIds.toList(),
      'productIds': filter.productIds.toList(),
      'minValueCents': filter.minValue?.cents,
      'maxValueCents': filter.maxValue?.cents,
    };
  }

  ReportFilterState _filterFromMap(Map<String, dynamic> map) {
    final startIso = map['customRangeStart'] as String?;
    final endIso = map['customRangeEnd'] as String?;
    final customRange = (startIso != null && endIso != null)
        ? DateTimeRange(start: DateTime.parse(startIso), end: DateTime.parse(endIso))
        : null;

    return ReportFilterState(
      periodPreset: ReportPeriodPreset.values.byName(
        map['periodPreset'] as String? ?? ReportPeriodPreset.currentMonth.name,
      ),
      customRange: customRange,
      boxIds: Set<String>.from(map['boxIds'] as List? ?? const []),
      categoryIds: Set<String>.from(map['categoryIds'] as List? ?? const []),
      productTypeIds: Set<String>.from(map['productTypeIds'] as List? ?? const []),
      productIds: Set<String>.from(map['productIds'] as List? ?? const []),
      minValue: (map['minValueCents'] as num?) == null ? null : Money((map['minValueCents'] as num).toInt()),
      maxValue: (map['maxValueCents'] as num?) == null ? null : Money((map['maxValueCents'] as num).toInt()),
    );
  }
}
