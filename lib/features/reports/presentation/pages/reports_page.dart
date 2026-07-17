import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:buy_control/features/reports/presentation/controllers/report_filter_state.dart';
import 'package:buy_control/features/reports/presentation/controllers/reports_controller.dart';
import 'package:buy_control/features/reports/presentation/pages/report_export_sheet.dart';
import 'package:buy_control/features/reports/presentation/pages/report_filters_sheet.dart';
import 'package:buy_control/features/reports/presentation/widgets/report_evolution_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Relatório consolidado: filtros de período/Boxes/categoria/tipo/produto/
/// valor, métricas detalhadas, modo de comparação (dois conjuntos de
/// filtros lado a lado) e exportação (contratos prontos, geração real de
/// arquivo fica para uma etapa futura).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  void _openFilters(BuildContext context) {
    AppBottomSheet.show(context, child: const ReportFiltersSheet());
  }

  void _openExport(BuildContext context) {
    AppBottomSheet.show(context, child: const ReportExportSheet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText.title('Relatórios', fontSize: AppFontSizes.fz09),
        actions: [
          GetBuilder<ReportsController>(
            builder: (controller) => IconButton(
              icon: Icon(
                LucideIcons.gitCompare,
                color: controller.compareMode ? AppColors.accent : null,
              ),
              tooltip: 'Comparar',
              onPressed: controller.toggleCompareMode,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.listFilter),
            tooltip: 'Filtros',
            onPressed: () => _openFilters(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: 'Exportar',
            onPressed: () => _openExport(context),
          ),
        ],
      ),
      body: GetBuilder<ReportsController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: LucideIcons.chartBar,
                title: 'Nenhuma Box com dados ainda',
                message: 'Crie Boxes e registre lançamentos para consolidar relatórios aqui.',
                actionLabel: 'Filtros',
                onAction: () => _openFilters(context),
              );
            case ViewStatus.success:
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _ReportSection(
                      title: controller.compareMode ? 'Lado A' : null,
                      periodLabel: controller.filterFor(ReportSide.a).periodLabel,
                      report: controller.reportA,
                      onOpenFilters: () => _openFilters(context),
                    ),
                    if (controller.compareMode) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),
                      _ReportSection(
                        title: 'Lado B',
                        periodLabel: controller.filterFor(ReportSide.b).periodLabel,
                        report: controller.reportB,
                        onOpenFilters: () => _openFilters(context),
                      ),
                    ],
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String? title;
  final String periodLabel;
  final ConsolidatedReport? report;
  final VoidCallback onOpenFilters;

  const _ReportSection({
    required this.title,
    required this.periodLabel,
    required this.report,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = report;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          AppText.title(title!, fontSize: AppFontSizes.fz09),
          const SizedBox(height: AppSpacing.xs),
        ],
        GestureDetector(
          onTap: onOpenFilters,
          child: Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: AppSpacing.xs),
              AppText(periodLabel, fontSize: AppFontSizes.fz06, color: AppColors.textSecondary(isDark)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (r == null || r.isEmpty)
          const EmptyStateView(
            icon: LucideIcons.chartBar,
            title: 'Nenhum lançamento nos filtros atuais',
            message: 'Ajuste o período, as Boxes ou os demais filtros para ver o relatório.',
          )
        else ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subtitle('Total consolidado', color: AppColors.textSecondary(isDark)),
                const SizedBox(height: AppSpacing.xs),
                AppText.title(r.total.formatted, fontSize: AppFontSizes.fz11),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  '${r.transactionCount} lançamentos · ${r.itemCount} itens',
                  fontSize: AppFontSizes.fz06,
                  color: AppColors.textSecondary(isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _MetricCard(label: 'Média por Box', value: r.averagePerBox.formatted)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _MetricCard(label: 'Média por dia', value: r.averagePerDay.formatted)),
            ],
          ),
          if (r.topBox != null || r.topCategory != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (r.topBox != null)
                  Expanded(child: _MetricCard(label: 'Box com maior gasto', value: r.topBox!.name, hint: r.topBox!.total.formatted)),
                if (r.topBox != null && r.topCategory != null) const SizedBox(width: AppSpacing.sm),
                if (r.topCategory != null)
                  Expanded(
                    child: _MetricCard(
                      label: 'Categoria com maior gasto',
                      value: r.topCategory!.name,
                      hint: r.topCategory!.total.formatted,
                    ),
                  ),
              ],
            ),
          ],
          if (r.mostPurchasedProduct != null || r.highestImpactProduct != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (r.mostPurchasedProduct != null)
                  Expanded(
                    child: _MetricCard(
                      label: 'Produto mais comprado',
                      value: r.mostPurchasedProduct!.name,
                      hint: '${r.mostPurchasedProduct!.quantity.toStringAsFixed(r.mostPurchasedProduct!.quantity % 1 == 0 ? 0 : 1)} un.',
                    ),
                  ),
                if (r.mostPurchasedProduct != null && r.highestImpactProduct != null) const SizedBox(width: AppSpacing.sm),
                if (r.highestImpactProduct != null)
                  Expanded(
                    child: _MetricCard(
                      label: 'Maior impacto financeiro',
                      value: r.highestImpactProduct!.name,
                      hint: r.highestImpactProduct!.total.formatted,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ReportEvolutionChart(points: r.evolution),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const _MetricCard({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle(label, color: AppColors.textSecondary(isDark)),
          const SizedBox(height: AppSpacing.xs),
          AppText(value, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(hint!, fontSize: AppFontSizes.fz05, color: AppColors.textSecondary(isDark)),
          ],
        ],
      ),
    );
  }
}
