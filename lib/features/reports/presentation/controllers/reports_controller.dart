import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_boxes.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/usecases/get_products.dart';
import 'package:buy_control/features/reports/data/repositories/report_preset_repository.dart';
import 'package:buy_control/features/reports/domain/usecases/export_report.dart';
import 'package:buy_control/features/reports/domain/usecases/get_boxes_totals.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:buy_control/features/reports/presentation/controllers/report_filter_state.dart';
import 'package:buy_control/features/reports/presentation/controllers/saved_filter_preset.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportsController extends GetxController {
  final GetBoxesTotals getBoxesTotals;
  final GetConsolidatedReport getConsolidatedReport;
  final ExportReport exportReport;
  final GetBoxes getBoxes;
  final GetCategories getCategories;
  final GetProductTypes getProductTypes;
  final GetProducts getProducts;
  final ReportPresetRepository reportPresetRepository;

  ReportsController({
    required this.getBoxesTotals,
    required this.getConsolidatedReport,
    required this.exportReport,
    required this.getBoxes,
    required this.getCategories,
    required this.getProductTypes,
    required this.getProducts,
    required this.reportPresetRepository,
  });

  ViewStatus status = ViewStatus.initial;
  String? errorMessage;

  List<BoxTotal> boxTotals = [];
  List<BoxEntity> boxes = [];
  List<CategoryEntity> categories = [];
  List<ProductTypeEntity> productTypes = [];
  List<ProductEntity> products = [];

  final ReportFilterState filterA = ReportFilterState();
  final ReportFilterState filterB = ReportFilterState();
  bool compareMode = false;

  ConsolidatedReport? reportA;
  ConsolidatedReport? reportB;

  final List<SavedFilterPreset> savedPresets = [];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  ReportFilterState filterFor(ReportSide side) => side == ReportSide.a ? filterA : filterB;

  Future<void> load() async {
    status = ViewStatus.loading;
    errorMessage = null;
    update();

    final presets = await reportPresetRepository.getAll();
    savedPresets
      ..clear()
      ..addAll(presets);

    final boxTotalsResult = await getBoxesTotals();
    if (boxTotalsResult.isFailure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(boxTotalsResult.failureOrNull!);
      update();
      return;
    }
    boxTotals = boxTotalsResult.dataOrNull!;

    final boxesResult = await getBoxes();
    boxesResult.fold((data) => boxes = data, (_) {});
    final categoriesResult = await getCategories(includeInactive: true);
    categoriesResult.fold((data) => categories = data, (_) {});
    final typesResult = await getProductTypes(includeInactive: true);
    typesResult.fold((data) => productTypes = data, (_) {});
    final productsResult = await getProducts(includeInactive: true);
    productsResult.fold((data) => products = data, (_) {});

    await _runReports();

    status = boxTotals.isEmpty ? ViewStatus.empty : ViewStatus.success;
    update();
  }

  Future<void> _runReports() async {
    final resultA = await getConsolidatedReport(
      boxIds: filterA.boxIds.toList(),
      start: filterA.start,
      end: filterA.end,
      categoryIds: filterA.categoryIds.toList(),
      productTypeIds: filterA.productTypeIds.toList(),
      productIds: filterA.productIds.toList(),
      minValue: filterA.minValue,
      maxValue: filterA.maxValue,
    );
    resultA.fold((data) => reportA = data, (failure) {
      reportA = null;
      errorMessage = FailurePresenter.present(failure);
    });

    if (compareMode) {
      final resultB = await getConsolidatedReport(
        boxIds: filterB.boxIds.toList(),
        start: filterB.start,
        end: filterB.end,
        categoryIds: filterB.categoryIds.toList(),
        productTypeIds: filterB.productTypeIds.toList(),
        productIds: filterB.productIds.toList(),
        minValue: filterB.minValue,
        maxValue: filterB.maxValue,
      );
      resultB.fold((data) => reportB = data, (_) => reportB = null);
    } else {
      reportB = null;
    }
  }

  Future<void> _refresh() async {
    await _runReports();
    update();
  }

  void toggleCompareMode() {
    compareMode = !compareMode;
    _refresh();
  }

  void setPeriodPreset(ReportSide side, ReportPeriodPreset preset) {
    final f = filterFor(side);
    f.periodPreset = preset;
    if (preset != ReportPeriodPreset.custom) f.customRange = null;
    _refresh();
  }

  void setCustomRange(ReportSide side, DateTimeRange range) {
    final f = filterFor(side);
    f.periodPreset = ReportPeriodPreset.custom;
    f.customRange = range;
    _refresh();
  }

  void toggleBox(ReportSide side, String boxId) {
    final f = filterFor(side);
    final allIds = boxes.map((b) => b.id).toSet();
    final current = f.boxIds.isEmpty ? Set<String>.of(allIds) : Set<String>.of(f.boxIds);
    if (!current.remove(boxId)) current.add(boxId);
    f.boxIds
      ..clear()
      ..addAll(current.length >= allIds.length ? <String>{} : current);
    _refresh();
  }

  bool isBoxSelected(ReportSide side, String boxId) {
    final f = filterFor(side);
    return f.boxIds.isEmpty || f.boxIds.contains(boxId);
  }

  void selectAllBoxes(ReportSide side) {
    filterFor(side).boxIds.clear();
    _refresh();
  }

  void toggleCategories(ReportSide side, Set<String> ids) {
    final f = filterFor(side);
    f.categoryIds
      ..clear()
      ..addAll(ids);
    _refresh();
  }

  void toggleProductTypes(ReportSide side, Set<String> ids) {
    final f = filterFor(side);
    f.productTypeIds
      ..clear()
      ..addAll(ids);
    _refresh();
  }

  void toggleProducts(ReportSide side, Set<String> ids) {
    final f = filterFor(side);
    f.productIds
      ..clear()
      ..addAll(ids);
    _refresh();
  }

  void setMinValue(ReportSide side, Money? value) {
    filterFor(side).minValue = value;
    _refresh();
  }

  void setMaxValue(ReportSide side, Money? value) {
    filterFor(side).maxValue = value;
    _refresh();
  }

  void clearFilters(ReportSide side) {
    final f = filterFor(side);
    f.boxIds.clear();
    f.categoryIds.clear();
    f.productTypeIds.clear();
    f.productIds.clear();
    f.minValue = null;
    f.maxValue = null;
    f.periodPreset = ReportPeriodPreset.currentMonth;
    f.customRange = null;
    _refresh();
  }

  Future<void> savePreset(String name) async {
    if (name.trim().isEmpty) return;
    final preset = SavedFilterPreset(name: name.trim(), filter: filterA.copy());
    savedPresets.removeWhere((p) => p.name == preset.name);
    savedPresets.add(preset);
    update();
    await reportPresetRepository.save(preset);
  }

  void applyPreset(SavedFilterPreset preset, {ReportSide side = ReportSide.a}) {
    final applied = preset.filter.copy();
    final target = filterFor(side);
    target.periodPreset = applied.periodPreset;
    target.customRange = applied.customRange;
    target.boxIds
      ..clear()
      ..addAll(applied.boxIds);
    target.categoryIds
      ..clear()
      ..addAll(applied.categoryIds);
    target.productTypeIds
      ..clear()
      ..addAll(applied.productTypeIds);
    target.productIds
      ..clear()
      ..addAll(applied.productIds);
    target.minValue = applied.minValue;
    target.maxValue = applied.maxValue;
    _refresh();
  }

  Future<void> removePreset(SavedFilterPreset preset) async {
    savedPresets.remove(preset);
    update();
    await reportPresetRepository.remove(preset.name);
  }

  Map<String, String> _appliedFiltersFor(ReportFilterState filter) {
    final applied = <String, String>{};
    if (filter.boxIds.isNotEmpty) {
      final names = boxes.where((b) => filter.boxIds.contains(b.id)).map((b) => b.name).join(', ');
      if (names.isNotEmpty) applied['Boxes'] = names;
    }
    if (filter.categoryIds.isNotEmpty) {
      final names = categories.where((c) => filter.categoryIds.contains(c.id)).map((c) => c.name).join(', ');
      if (names.isNotEmpty) applied['Categorias'] = names;
    }
    if (filter.productTypeIds.isNotEmpty) {
      final names = productTypes.where((t) => filter.productTypeIds.contains(t.id)).map((t) => t.name).join(', ');
      if (names.isNotEmpty) applied['Tipos de produto'] = names;
    }
    if (filter.productIds.isNotEmpty) {
      final names = products.where((p) => filter.productIds.contains(p.id)).map((p) => p.name).join(', ');
      if (names.isNotEmpty) applied['Produtos'] = names;
    }
    if (filter.minValue != null) applied['Valor mínimo'] = filter.minValue!.formatted;
    if (filter.maxValue != null) applied['Valor máximo'] = filter.maxValue!.formatted;
    return applied;
  }

  Future<void> export(ExportFormat format) async {
    final filter = filterFor(ReportSide.a);
    final appliedFilters = _appliedFiltersFor(filter);
    final result = await exportReport(
      format,
      report: reportA,
      title: 'Relatório',
      periodLabel: filter.periodLabel,
      appliedFilters: appliedFilters.isEmpty ? null : appliedFilters,
    );
    result.fold(
      (path) => Get.snackbar('Exportação', path == null ? 'Ação concluída.' : 'Arquivo gerado: $path'),
      (failure) => Get.snackbar(
        failure is NotImplementedFailure ? 'Em breve' : 'Erro ao exportar',
        FailurePresenter.present(failure),
      ),
    );
  }
}
