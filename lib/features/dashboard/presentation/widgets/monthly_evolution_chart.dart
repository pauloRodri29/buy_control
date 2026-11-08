import 'package:buy_control/app/theme/theme_context.dart';
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
                child: AppText.small(
                  'Sem dados no período.',
                  
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else
            SizedBox(height: 200, child: _Chart(points: points)),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<MonthlyPoint> points;

  const _Chart({required this.points});

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
          getDrawingHorizontalLine: (_) => FlLine(color: context.colors.outlineVariant, strokeWidth: 1),
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
                  child: AppText.caption(
                    _monthAbbreviations[month.month - 1],
                    
                    color: context.colors.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.colors.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x.toInt()];
              return BarTooltipItem(
                point.total.formatted,
                context.text.labelMedium!.copyWith(color: context.colors.onSurface, fontWeight: FontWeight.w600),
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
                  color: context.colors.primary,
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
