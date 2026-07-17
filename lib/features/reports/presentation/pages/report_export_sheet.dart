import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/reports/domain/usecases/export_report.dart';
import 'package:buy_control/features/reports/presentation/controllers/reports_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _ExportOption {
  final ExportFormat format;
  final String label;
  final IconData icon;
  const _ExportOption({required this.format, required this.label, required this.icon});
}

const _options = [
  _ExportOption(format: ExportFormat.pdf, label: 'PDF', icon: LucideIcons.fileText),
  _ExportOption(format: ExportFormat.csv, label: 'CSV', icon: LucideIcons.sheet),
  _ExportOption(format: ExportFormat.share, label: 'Compartilhar', icon: LucideIcons.share2),
  _ExportOption(format: ExportFormat.print, label: 'Imprimir', icon: LucideIcons.printer),
  _ExportOption(format: ExportFormat.jsonBackup, label: 'Backup em JSON', icon: LucideIcons.databaseBackup),
];

/// Lista as opções de exportação previstas no contrato `ReportExporter`.
/// A geração de arquivo real ainda não existe — cada opção já chama
/// `ExportReport` e mostra o resultado, provando a integração ponta a
/// ponta mesmo com a implementação-tronco (`StubReportExporter`).
class ReportExportSheet extends StatelessWidget {
  const ReportExportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<ReportsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.title('Exportar relatório', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.md),
        ..._options.map(
          (option) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(option.icon, color: AppColors.textPrimary(isDark)),
            title: AppText(option.label, fontWeight: FontWeight.w600),
            onTap: () {
              Navigator.of(context).pop();
              controller.export(option.format);
            },
          ),
        ),
      ],
    );
  }
}
