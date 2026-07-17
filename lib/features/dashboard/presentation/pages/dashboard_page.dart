import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:buy_control/features/dashboard/presentation/widgets/dashboard_filters_section.dart';
import 'package:buy_control/features/dashboard/presentation/widgets/monthly_evolution_chart.dart';
import 'package:buy_control/features/dashboard/presentation/widgets/spending_by_box_chart.dart';
import 'package:buy_control/features/dashboard/presentation/widgets/spending_by_category_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.title('Buy Control', fontSize: AppFontSizes.fz09)),
      body: GetBuilder<DashboardController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
            case ViewStatus.empty:
              return const EmptyStateView(
                icon: LucideIcons.layoutDashboard,
                title: 'Nenhum dado ainda',
                message: 'Crie sua primeira Box e registre um lançamento para ver o resumo aqui.',
              );
            case ViewStatus.success:
              final summary = controller.summary!;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subtitle('Total no mês', color: AppColors.textSecondary(isDark)),
                          const SizedBox(height: AppSpacing.xs),
                          AppText.title(summary.currentMonthTotal.formatted, fontSize: AppFontSizes.fz12),
                          const SizedBox(height: AppSpacing.xs),
                          if (summary.percentChangeVsPreviousMonth != null)
                            AppText(
                              '${summary.percentChangeVsPreviousMonth! >= 0 ? '+' : ''}'
                              '${summary.percentChangeVsPreviousMonth!.toStringAsFixed(1)}% vs. mês anterior',
                              color: summary.percentChangeVsPreviousMonth! > 0 ? AppColors.error : AppColors.success,
                              fontSize: AppFontSizes.fz06,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.subtitle('Média diária', color: AppColors.textSecondary(isDark)),
                                AppText(summary.dailyAverageCurrentMonth.formatted, fontWeight: FontWeight.w600),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.subtitle('Lançamentos', color: AppColors.textSecondary(isDark)),
                                AppText('${summary.transactionCountCurrentMonth}', fontWeight: FontWeight.w600),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.subtitle('Boxes ativas', color: AppColors.textSecondary(isDark)),
                                AppText('${summary.activeBoxCount}', fontWeight: FontWeight.w600),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (summary.topBoxesCurrentMonth.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const AppText.subtitle('Boxes com maiores gastos no mês'),
                      const SizedBox(height: AppSpacing.sm),
                      ...summary.topBoxesCurrentMonth.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(b.boxName, fontWeight: FontWeight.w600),
                                AppText(b.total.formatted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (summary.recentTransactions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const AppText.subtitle('Gastos recentes'),
                      const SizedBox(height: AppSpacing.sm),
                      ...summary.recentTransactions.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: AppText(
                                    t.title ?? (t.items.isNotEmpty ? t.items.first.nameSnapshot : 'Lançamento'),
                                    fontWeight: FontWeight.w600,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppText(DateTimeFormatter.relative(t.occurredAt), fontSize: AppFontSizes.fz05),
                                const SizedBox(width: AppSpacing.sm),
                                AppText(t.total.formatted, fontWeight: FontWeight.w600),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    DashboardFiltersSection(controller: controller),
                    const SizedBox(height: AppSpacing.lg),
                    _buildChartsSection(context, controller),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, DashboardController controller) {
    switch (controller.chartsStatus) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return Column(
          children: [
            LoadingSkeleton(height: 236, borderRadius: AppRadius.borderLg),
            const SizedBox(height: AppSpacing.md),
            LoadingSkeleton(height: 236, borderRadius: AppRadius.borderLg),
            const SizedBox(height: AppSpacing.md),
            LoadingSkeleton(height: 236, borderRadius: AppRadius.borderLg),
          ],
        );
      case ViewStatus.error:
        return ErrorStateView(
          message: controller.chartsErrorMessage ?? 'Erro ao carregar gráficos.',
          onRetry: controller.load,
        );
      case ViewStatus.empty:
        return const EmptyStateView(
          icon: LucideIcons.chartColumn,
          title: 'Nenhum gasto no período selecionado.',
          message: 'Ajuste os filtros ou registre lançamentos para ver os gráficos aqui.',
        );
      case ViewStatus.success:
        final charts = controller.charts!;
        return Column(
          children: [
            MonthlyEvolutionChart(points: charts.monthlyEvolution),
            const SizedBox(height: AppSpacing.md),
            SpendingByCategoryChart(items: charts.spendingByCategory),
            const SizedBox(height: AppSpacing.md),
            SpendingByBoxChart(items: charts.spendingByBox),
          ],
        );
    }
  }
}
