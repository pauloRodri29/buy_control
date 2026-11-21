import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/reports/domain/usecases/export_report.dart';
import 'package:buy_control/features/reports/presentation/controllers/reports_controller.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/presentation/plan_features.dart';

class _ExportOption {
  final ExportFormat format;
  final String label;
  final IconData icon;
  const _ExportOption({required this.format, required this.label, required this.icon});
}

const _options = [
  _ExportOption(format: ExportFormat.pdf, label: 'PDF', icon: Symbols.description),
  _ExportOption(format: ExportFormat.csv, label: 'CSV', icon: Symbols.table_chart),
  _ExportOption(format: ExportFormat.share, label: 'reports.share', icon: Symbols.share),
  _ExportOption(format: ExportFormat.print, label: 'reports.print', icon: Symbols.print),
  _ExportOption(format: ExportFormat.jsonBackup, label: 'reports.jsonBackup', icon: Symbols.backup),
];

/// Lista as opções de exportação previstas no contrato `ReportExporter`.
/// A geração de arquivo real ainda não existe — cada opção já chama
/// `ExportReport` e mostra o resultado, provando a integração ponta a
/// ponta mesmo com a implementação-tronco (`StubReportExporter`).
class ReportExportSheet extends StatelessWidget {
  const ReportExportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.heading('reports.exportReport'.tr, ),
        const SizedBox(height: AppSpacing.md),
        ..._options.map(
          (option) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(option.icon, color: context.colors.onSurface),
            title: AppText(option.label.tr, fontWeight: FontWeight.w600),
            onTap: () {
              Navigator.of(context).pop();
              if (!PlanFeatures.ensure(FeatureKey.exportPdf)) return;
              controller.export(option.format);
            },
          ),
        ),
      ],
    );
  }
}
