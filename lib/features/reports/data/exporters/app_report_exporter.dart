import 'dart:io';

import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/reports/data/exporters/pdf_report_builder.dart';
import 'package:buy_control/features/reports/domain/repositories/report_exporter.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Implementação real do [ReportExporter]: gera o PDF do relatório
/// consolidado e integra com share/print do sistema operacional via
/// `printing`. CSV e backup em JSON permanecem fora do escopo desta etapa.
class AppReportExporter implements ReportExporter {
  final PdfReportBuilder _pdfBuilder;

  const AppReportExporter({PdfReportBuilder pdfBuilder = const PdfReportBuilder()}) : _pdfBuilder = pdfBuilder;

  @override
  Future<Result<String>> exportToPdf(
    ConsolidatedReport report, {
    required String title,
    String? periodLabel,
    Map<String, String>? appliedFilters,
  }) async {
    try {
      final bytes = await _pdfBuilder.build(
        report: report,
        title: title,
        periodLabel: periodLabel,
        appliedFilters: appliedFilters,
      );
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return Success(filePath);
    } catch (_) {
      return const Failure(UnknownFailure('Não foi possível gerar o PDF do relatório.'));
    }
  }

  @override
  Future<Result<String>> exportToCsv(ConsolidatedReport report, {required String title}) async {
    return const Failure(NotImplementedFailure('Exportação em CSV estará disponível em breve.'));
  }

  @override
  Future<Result<void>> share(
    ConsolidatedReport report, {
    required String title,
    String? periodLabel,
    Map<String, String>? appliedFilters,
  }) async {
    try {
      final bytes = await _pdfBuilder.build(
        report: report,
        title: title,
        periodLabel: periodLabel,
        appliedFilters: appliedFilters,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'relatorio.pdf');
      return const Success(null);
    } catch (_) {
      return const Failure(UnknownFailure('Não foi possível compartilhar o relatório.'));
    }
  }

  @override
  Future<Result<void>> print(
    ConsolidatedReport report, {
    required String title,
    String? periodLabel,
    Map<String, String>? appliedFilters,
  }) async {
    try {
      final bytes = await _pdfBuilder.build(
        report: report,
        title: title,
        periodLabel: periodLabel,
        appliedFilters: appliedFilters,
      );
      await Printing.layoutPdf(onLayout: (format) async => bytes);
      return const Success(null);
    } catch (_) {
      return const Failure(UnknownFailure('Não foi possível imprimir o relatório.'));
    }
  }

  @override
  Future<Result<String>> backupToJson() async {
    // Backup completo do app em JSON é uma feature separada
    // (lib/features/backup/), fora do escopo deste exportador que só lida
    // com o relatório consolidado.
    return const Failure(NotImplementedFailure('Backup em JSON estará disponível em breve.'));
  }
}
