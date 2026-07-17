import 'package:flutter/material.dart';

enum ReportPeriodPreset { today, last7Days, currentMonth, previousMonth, currentYear, custom }

enum ReportSide { a, b }

extension ReportPeriodPresetLabel on ReportPeriodPreset {
  String get label {
    switch (this) {
      case ReportPeriodPreset.today:
        return 'Hoje';
      case ReportPeriodPreset.last7Days:
        return 'Últimos 7 dias';
      case ReportPeriodPreset.currentMonth:
        return 'Mês atual';
      case ReportPeriodPreset.previousMonth:
        return 'Mês anterior';
      case ReportPeriodPreset.currentYear:
        return 'Ano atual';
      case ReportPeriodPreset.custom:
        return 'Personalizado';
    }
  }
}

/// Estado de um conjunto de filtros do relatório. É replicado em duas
/// instâncias (Lado A / Lado B) para alimentar o modo de comparação sem
/// precisar de um caso de uso dedicado por tipo de comparação.
class ReportFilterState {
  ReportPeriodPreset periodPreset;
  DateTimeRange? customRange;
  Set<String> boxIds;
  Set<String> categoryIds;
  Set<String> productTypeIds;
  Set<String> productIds;
  double? minValue;
  double? maxValue;

  ReportFilterState({
    this.periodPreset = ReportPeriodPreset.currentMonth,
    this.customRange,
    Set<String>? boxIds,
    Set<String>? categoryIds,
    Set<String>? productTypeIds,
    Set<String>? productIds,
    this.minValue,
    this.maxValue,
  })  : boxIds = boxIds ?? {},
        categoryIds = categoryIds ?? {},
        productTypeIds = productTypeIds ?? {},
        productIds = productIds ?? {};

  ReportFilterState copy() => ReportFilterState(
        periodPreset: periodPreset,
        customRange: customRange,
        boxIds: Set.of(boxIds),
        categoryIds: Set.of(categoryIds),
        productTypeIds: Set.of(productTypeIds),
        productIds: Set.of(productIds),
        minValue: minValue,
        maxValue: maxValue,
      );

  DateTime? get start {
    final now = DateTime.now();
    switch (periodPreset) {
      case ReportPeriodPreset.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriodPreset.last7Days:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case ReportPeriodPreset.currentMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriodPreset.previousMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        return DateTime(prevMonth.year, prevMonth.month, 1);
      case ReportPeriodPreset.currentYear:
        return DateTime(now.year, 1, 1);
      case ReportPeriodPreset.custom:
        return customRange?.start;
    }
  }

  DateTime? get end {
    final now = DateTime.now();
    switch (periodPreset) {
      case ReportPeriodPreset.today:
      case ReportPeriodPreset.last7Days:
      case ReportPeriodPreset.currentMonth:
      case ReportPeriodPreset.currentYear:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriodPreset.previousMonth:
        return DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
      case ReportPeriodPreset.custom:
        final rangeEnd = customRange?.end;
        if (rangeEnd == null) return null;
        return DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day, 23, 59, 59);
    }
  }

  String get periodLabel {
    if (periodPreset == ReportPeriodPreset.custom && customRange != null) {
      final s = customRange!.start;
      final e = customRange!.end;
      return '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')} a '
          '${e.day.toString().padLeft(2, '0')}/${e.month.toString().padLeft(2, '0')}';
    }
    return periodPreset.label;
  }

  bool get hasActiveFilters =>
      boxIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      productTypeIds.isNotEmpty ||
      productIds.isNotEmpty ||
      minValue != null ||
      maxValue != null;
}
