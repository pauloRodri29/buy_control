import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:buy_control/features/reports/presentation/controllers/report_filter_state.dart';
import 'package:buy_control/features/reports/presentation/controllers/reports_controller.dart';
import 'package:buy_control/features/reports/presentation/pages/report_export_sheet.dart';
import 'package:buy_control/features/reports/presentation/pages/report_filters_sheet.dart';
import 'package:buy_control/features/reports/presentation/widgets/report_evolution_chart.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

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
        title: const AppText.heading('Relatórios', ),
        actions: [
          GetBuilder<ReportsController>(
            builder: (controller) => IconButton(
              icon: Icon(
                Symbols.compare_arrows,
                color: controller.compareMode ? context.colors.primary : null,
              ),
              tooltip: 'Comparar',
              onPressed: controller.toggleCompareMode,
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.filter_list),
            tooltip: 'Filtros',
            onPressed: () => _openFilters(context),
          ),
          IconButton(
            icon: const Icon(Symbols.share),
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
                icon: Symbols.bar_chart,
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
    final r = report;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          AppText.heading(title!, ),
          const SizedBox(height: AppSpacing.xs),
        ],
        GestureDetector(
          onTap: onOpenFilters,
          child: Row(
            children: [
              Icon(Symbols.calendar_today, size: 14, color: context.colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              AppText.small(periodLabel,  color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (r == null || r.isEmpty)
          const EmptyStateView(
            icon: Symbols.bar_chart,
            title: 'Nenhum lançamento nos filtros atuais',
            message: 'Ajuste o período, as Boxes ou os demais filtros para ver o relatório.',
          )
        else ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subtitle('Total consolidado'),
                const SizedBox(height: AppSpacing.xs),
                AppText.title(r.total.formatted, ),
                const SizedBox(height: AppSpacing.xs),
                AppText.small(
                  '${r.transactionCount} lançamentos · ${r.itemCount} itens',
                  
                  color: context.colors.onSurfaceVariant,
                ),
                if (r.planning != null && r.planning!.purchasedCount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText.small(
                    'Boxes ${r.boxesTotal.formatted} · Planejamento ${r.planning!.purchasedTotal.formatted}',
                    
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
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
          if (r.planning != null && !r.planning!.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _PlanningCard(planning: r.planning!, realized: r.total),
          ],
          const SizedBox(height: AppSpacing.sm),
          ReportEvolutionChart(points: r.evolution),
        ],
      ],
    );
  }
}

/// Realizado × previsto vindo do Planejamento no período do relatório.
class _PlanningCard extends StatelessWidget {
  final PlanningReportSummary planning;
  final Money realized;

  const _PlanningCard({required this.planning, required this.realized});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final projected = realized + planning.forecastPending;
    final hasGoal = !planning.goalTotal.isZero;
    final overGoal = hasGoal && planning.plannedInBoards > planning.goalTotal;

    Widget row(String label, String value, {Color? color, bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: AppText.small(label,  color: secondary)),
            AppText.small(
              value,
              
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.view_kanban, size: 16, color: secondary),
              const SizedBox(width: AppSpacing.xs),
              const AppText('Planejamento', fontWeight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          row('Comprado (${planning.purchasedCount} itens)', planning.purchasedTotal.formatted),
          row('Ainda previsto (${planning.pendingCount} itens)', planning.forecastPending.formatted),
          row('Projeção de gasto do período', projected.formatted, bold: true),
          if (hasGoal) ...[
            const SizedBox(height: AppSpacing.sm),
            row('Metas dos quadros (${planning.boardsInPeriod})', planning.goalTotal.formatted),
            row('Planejado nesses quadros', planning.plannedInBoards.formatted),
            row(
              overGoal ? 'Acima das metas' : 'Margem até as metas',
              (overGoal
                      ? planning.plannedInBoards - planning.goalTotal
                      : planning.goalTotal - planning.plannedInBoards)
                  .formatted,
              color: overGoal ? context.colors.error : context.semantic.success,
            ),
          ],
          if (planning.purchasedByBoard.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText.subtitle('Comprado por quadro', color: secondary),
            const SizedBox(height: AppSpacing.xs),
            for (final b in planning.purchasedByBoard) row(b.name, b.total.formatted),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppText.subtitle(
            'Projeção = total realizado no período (Boxes + Planejamento) + itens pendentes dos quadros '
            'com previsão no período.',
            color: secondary,
          ),
        ],
      ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle(label),
          const SizedBox(height: AppSpacing.xs),
          AppText(value, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText.caption(hint!,  color: context.colors.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}
