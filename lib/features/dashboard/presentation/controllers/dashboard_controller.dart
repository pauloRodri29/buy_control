import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_boxes.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_charts.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DashboardPeriod { thisMonth, lastMonth, thisYear, custom }

class DashboardController extends GetxController {
  final GetDashboardSummary getDashboardSummary;
  final GetDashboardCharts getDashboardCharts;
  final GetBoxes getBoxes;
  final GetCategories getCategories;

  DashboardController({
    required this.getDashboardSummary,
    required this.getDashboardCharts,
    required this.getBoxes,
    required this.getCategories,
  });

  ViewStatus status = ViewStatus.initial;
  DashboardSummary? summary;
  String? errorMessage;

  ViewStatus chartsStatus = ViewStatus.initial;
  DashboardCharts? charts;
  String? chartsErrorMessage;

  List<BoxEntity> boxes = [];
  List<CategoryEntity> categories = [];

  DashboardPeriod period = DashboardPeriod.thisMonth;
  DateTimeRange? customRange;
  String? selectedBoxId;
  String? selectedCategoryId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    chartsStatus = ViewStatus.loading;
    update();

    if (boxes.isEmpty || categories.isEmpty) {
      final boxesResult = await getBoxes();
      boxesResult.fold((data) => boxes = data, (_) {});
      final categoriesResult = await getCategories();
      categoriesResult.fold((data) => categories = data, (_) {});
    }

    final summaryResult = await getDashboardSummary();
    summaryResult.fold((data) {
      summary = data;
      status = data.activeBoxCount == 0 ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });

    final range = _periodRange();
    final chartsResult = await getDashboardCharts(
      periodStart: range.start,
      periodEnd: range.end,
      boxId: selectedBoxId,
      categoryId: selectedCategoryId,
    );
    chartsResult.fold((data) {
      charts = data;
      chartsStatus = data.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      chartsStatus = ViewStatus.error;
      chartsErrorMessage = FailurePresenter.present(failure);
    });

    update();
  }

  DateTimeRange _periodRange() {
    final now = DateTime.now();
    switch (period) {
      case DashboardPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case DashboardPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case DashboardPeriod.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case DashboardPeriod.custom:
        return customRange ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  Future<void> setPeriod(DashboardPeriod newPeriod) async {
    period = newPeriod;
    await load();
  }

  Future<void> setCustomRange(DateTimeRange range) async {
    period = DashboardPeriod.custom;
    customRange = range;
    await load();
  }

  Future<void> setBoxFilter(String? boxId) async {
    selectedBoxId = boxId;
    await load();
  }

  Future<void> setCategoryFilter(String? categoryId) async {
    selectedCategoryId = categoryId;
    await load();
  }
}
