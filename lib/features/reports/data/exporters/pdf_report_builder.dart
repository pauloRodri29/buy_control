import 'package:get/get.dart';
import 'dart:typed_data';

import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Monta o documento PDF do relatório consolidado. Só cuida de layout e
/// formatação a partir de um [ConsolidatedReport] já calculado — não
/// acessa repositórios nem conhece a camada de apresentação.
class PdfReportBuilder {
  const PdfReportBuilder();

  Future<Uint8List> build({
    required ConsolidatedReport report,
    required String title,
    String? periodLabel,
    Map<String, String>? appliedFilters,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            if (periodLabel != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('reports.periodPeriodLabel'.trParams({'periodLabel': periodLabel}), style: const pw.TextStyle(fontSize: 11)),
            ],
            pw.SizedBox(height: 8),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          if (appliedFilters != null && appliedFilters.isNotEmpty) _buildFiltersSection(appliedFilters),
          _buildSummarySection(report),
          pw.SizedBox(height: 16),
          pw.Text('common.products'.tr, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildProductsTable(report),
          pw.SizedBox(height: 16),
          _buildTotalsSection(report),
          pw.SizedBox(height: 24),
          pw.Text(
            'reports.generatedDateTime'.trParams({'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(DateTime.now())}),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildFiltersSection(Map<String, String> filters) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('reports.appliedFilters'.tr, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...filters.entries.map(
            (entry) => pw.Text('${entry.key}: ${entry.value}', style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(ConsolidatedReport report) {
    final rows = <List<String>>[
      ['common.total'.tr, report.total.formatted],
      if (report.planning != null && report.planning!.purchasedCount > 0) ...[
        ['reports.boxesTotal'.tr, report.boxesTotal.formatted],
        ['reports.purchasedThroughPlanning'.tr, report.planning!.purchasedTotal.formatted],
      ],
      if (report.planning != null && report.planning!.pendingCount > 0)
        ['reports.stillPlannedPlanning'.tr, report.planning!.forecastPending.formatted],
      if (report.planning != null && !report.planning!.goalTotal.isZero)
        ['reports.boardGoalsPeriod'.tr, report.planning!.goalTotal.formatted],
      ['reports.averagePerBox'.tr, report.averagePerBox.formatted],
      ['reports.averagePerDay'.tr, report.averagePerDay.formatted],
      ['common.entries'.tr, report.transactionCount.toString()],
      ['reports.items'.tr, report.itemCount.toString()],
      if (report.topBox != null)
        ['reports.boxHighestSpending'.tr, '${report.topBox!.name} (${report.topBox!.total.formatted})'],
      if (report.topCategory != null)
        ['reports.categoryHighestSpending'.tr, '${report.topCategory!.name} (${report.topCategory!.total.formatted})'],
      if (report.mostPurchasedProduct != null)
        ['reports.mostPurchasedProduct'.tr, '${report.mostPurchasedProduct!.name} (${_formatQuantity(report.mostPurchasedProduct!.quantity)})'],
      if (report.highestImpactProduct != null)
        ['reports.productBiggestImpact'.tr, '${report.highestImpactProduct!.name} (${report.highestImpactProduct!.total.formatted})'],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('reports.financialSummary'.tr, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['reports.metric'.tr, 'common.value'.tr],
          data: rows,
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        ),
      ],
    );
  }

  pw.Widget _buildProductsTable(ConsolidatedReport report) {
    if (report.productLines.isEmpty) {
      return pw.Text('reports.noProductsSelectedPeriod'.tr, style: const pw.TextStyle(fontSize: 10));
    }
    return pw.TableHelper.fromTextArray(
      headers: ['common.product'.tr, 'common.quantity'.tr, 'common.total'.tr],
      data: report.productLines
          .map((line) => [line.name, _formatQuantity(line.quantity), line.total.formatted])
          .toList(),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: const {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  pw.Widget _buildTotalsSection(ConsolidatedReport report) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'reports.grandTotalAmount'.trParams({'formatted': report.total.formatted}),
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  String _formatQuantity(double quantity) => QuantityFormatter.format(quantity);
}
