import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';

/// Contrato de exportação do relatório consolidado. A geração real dos
/// arquivos (PDF/CSV) e integração com share/print do sistema fica para
/// uma etapa futura — esta interface e seus casos de uso já deixam a
/// arquitetura pronta para isso, sem a presentation depender de detalhes
/// de implementação.
abstract interface class ReportExporter {
  Future<Result<String>> exportToPdf(
    ConsolidatedReport report, {
    required String title,
    String? periodLabel,
    Map<String, String>? appliedFilters,
  });
  Future<Result<String>> exportToCsv(ConsolidatedReport report, {required String title});
  Future<Result<void>> share(
    ConsolidatedReport report, {
    required String title,
    String? periodLabel,
    Map<String, String>? appliedFilters,
  });
  Future<Result<void>> print(
    ConsolidatedReport report, {
    required String title,
    String? periodLabel,
    Map<String, String>? appliedFilters,
  });
  Future<Result<String>> backupToJson();
}
