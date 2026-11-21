import 'package:buy_control/app/brand/app_logo.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/state/view_status.dart';
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
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/presentation/plan_features.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogoMark(size: 30),
            SizedBox(width: AppSpacing.sm),
            AppWordmark(fontSize: 20),
          ],
        ),
      ),
      body: GetBuilder<DashboardController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'common.unexpectedError'.tr, onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: Symbols.dashboard,
                title: 'dashboard.noDataYet'.tr,
                message: 'dashboard.createFirstBoxRecordEntry'.tr,
              );
            case ViewStatus.success:
              final summary = controller.summary!;
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subtitle('dashboard.totalMonth'.tr),
                          const SizedBox(height: AppSpacing.xs),
                          Text(summary.currentMonthTotal.formatted, style: context.text.headlineLarge),
                          const SizedBox(height: AppSpacing.xs),
                          if (summary.percentChangeVsPreviousMonth != null)
                            AppText.small(
                              'dashboard.vsLastMonthValueNumber'.trParams({'value': summary.percentChangeVsPreviousMonth! >= 0 ? '+' : '', 'toStringAsFixed': summary.percentChangeVsPreviousMonth!.toStringAsFixed(1)}),
                              color: summary.percentChangeVsPreviousMonth! > 0 ? context.colors.error : context.semantic.success,
                              
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
                                AppText.subtitle('dashboard.dailyAverage'.tr),
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
                                AppText.subtitle('common.entries'.tr),
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
                                AppText.subtitle('dashboard.activeBoxes'.tr),
                                AppText('${summary.activeBoxCount}', fontWeight: FontWeight.w600),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (summary.topBoxesCurrentMonth.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppText.subtitle('dashboard.boxesHighestSpendingMonth'.tr),
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
                      AppText.subtitle('dashboard.recentSpending'.tr),
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
                                    t.title ?? (t.items.isNotEmpty ? t.items.first.nameSnapshot : 'common.entry'.tr),
                                    fontWeight: FontWeight.w600,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppText.caption(DateTimeFormatter.relative(t.occurredAt), ),
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
          message: controller.chartsErrorMessage ?? 'dashboard.errorLoadingCharts'.tr,
          onRetry: controller.load,
        );
      case ViewStatus.empty:
        return EmptyStateView(
          icon: Symbols.insert_chart,
          title: 'dashboard.noSpendingSelectedPeriod'.tr,
          message: 'dashboard.adjustFiltersRecordEntriesSee'.tr,
        );
      case ViewStatus.success:
        final charts = controller.charts!;
        return Column(
          children: [
            MonthlyEvolutionChart(points: charts.monthlyEvolution),
            const SizedBox(height: AppSpacing.md),
            if (PlanFeatures.has(FeatureKey.dashboardCharts)) ...[
              SpendingByCategoryChart(items: charts.spendingByCategory),
              const SizedBox(height: AppSpacing.md),
              SpendingByBoxChart(items: charts.spendingByBox),
            ] else
              LockedFeatureCard(
                feature: FeatureKey.dashboardCharts,
                title: 'dashboard.chartsCategoryBox'.tr,
              ),
          ],
        );
    }
  }
}
