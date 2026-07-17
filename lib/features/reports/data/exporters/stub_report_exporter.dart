import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/reports/domain/repositories/report_exporter.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';

/// Implementação provisória: os contratos e o fluxo de UI já existem, mas
/// a geração real de arquivos (pacotes de PDF/CSV, share/print do SO)
/// fica para uma etapa futura.
class StubReportExporter implements ReportExporter {
  const StubReportExporter();

  @override
  Future<Result<String>> exportToPdf(ConsolidatedReport report, {required String title}) async {
    return const Failure(NotImplementedFailure('Exportação em PDF estará disponível em breve.'));
  }

  @override
  Future<Result<String>> exportToCsv(ConsolidatedReport report, {required String title}) async {
    return const Failure(NotImplementedFailure('Exportação em CSV estará disponível em breve.'));
  }

  @override
  Future<Result<void>> share(ConsolidatedReport report, {required String title}) async {
    return const Failure(NotImplementedFailure('Compartilhamento estará disponível em breve.'));
  }

  @override
  Future<Result<void>> print(ConsolidatedReport report, {required String title}) async {
    return const Failure(NotImplementedFailure('Impressão estará disponível em breve.'));
  }

  @override
  Future<Result<String>> backupToJson() async {
    return const Failure(NotImplementedFailure('Backup em JSON estará disponível em breve.'));
  }
}
