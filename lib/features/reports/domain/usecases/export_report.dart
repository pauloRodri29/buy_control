import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/reports/domain/repositories/report_exporter.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';

enum ExportFormat { pdf, csv, share, print, jsonBackup }

class ExportReport {
  final ReportExporter exporter;
  const ExportReport(this.exporter);

  Future<Result<String?>> call(
    ExportFormat format, {
    ConsolidatedReport? report,
    String title = 'Relatório',
    String? periodLabel,
    Map<String, String>? appliedFilters,
  }) async {
    switch (format) {
      case ExportFormat.pdf:
        return exporter.exportToPdf(report!, title: title, periodLabel: periodLabel, appliedFilters: appliedFilters);
      case ExportFormat.csv:
        return exporter.exportToCsv(report!, title: title);
      case ExportFormat.share:
        final result = await exporter.share(report!, title: title, periodLabel: periodLabel, appliedFilters: appliedFilters);
        return result.fold((_) => const Success(null), (f) => Failure(f));
      case ExportFormat.print:
        final result = await exporter.print(report!, title: title, periodLabel: periodLabel, appliedFilters: appliedFilters);
        return result.fold((_) => const Success(null), (f) => Failure(f));
      case ExportFormat.jsonBackup:
        return exporter.backupToJson();
    }
  }
}
