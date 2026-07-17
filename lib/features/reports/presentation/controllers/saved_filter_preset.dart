import 'package:buy_control/features/reports/presentation/controllers/report_filter_state.dart';

/// Combinação de filtros salva em memória para reaplicação rápida. Não é
/// persistida em disco nesta etapa — some ao reiniciar o app.
class SavedFilterPreset {
  final String name;
  final ReportFilterState filter;
  const SavedFilterPreset({required this.name, required this.filter});
}
