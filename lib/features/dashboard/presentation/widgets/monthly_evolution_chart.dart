import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _monthAbbreviations = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

class MonthlyEvolutionChart extends StatelessWidget {
  final List<MonthlyPoint> points;

  const MonthlyEvolutionChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasData = points.any((p) => !p.total.isZero);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Evolução mensal'),
          const SizedBox(height: AppSpacing.md),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: AppText(
                  'Sem dados no período.',
                  fontSize: AppFontSizes.fz06,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            )
          else
            SizedBox(height: 200, child: _Chart(points: points, isDark: isDark)),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<MonthlyPoint> points;
  final bool isDark;

  const _Chart({required this.points, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (max, p) {
      final value = p.total.toDouble();
      return value > max ? value : max;
    });
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border(isDark), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                final month = points[index].month;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: AppText(
                    _monthAbbreviations[month.month - 1],
                    fontSize: AppFontSizes.fz05,
                    color: AppColors.textSecondary(isDark),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceVariant(isDark),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x.toInt()];
              return BarTooltipItem(
                point.total.formatted,
                TextStyle(color: AppColors.textPrimary(isDark), fontSize: AppFontSizes.fz06, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].total.toDouble(),
                  color: AppColors.accent,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
