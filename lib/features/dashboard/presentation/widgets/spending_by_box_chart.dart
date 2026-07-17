import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _maxBars = 6;

class SpendingByBoxChart extends StatelessWidget {
  final List<NamedSpend> items;

  const SpendingByBoxChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = (items.where((e) => !e.total.isZero).toList()
          ..sort((a, b) => b.total.cents.compareTo(a.total.cents)))
        .take(_maxBars)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Gastos por Box'),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
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
            SizedBox(height: 220, child: _Chart(entries: entries, isDark: isDark)),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<NamedSpend> entries;
  final bool isDark;

  const _Chart({required this.entries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.fold<double>(0, (max, e) {
      final value = e.total.toDouble();
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
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                final name = entries[index].name;
                final label = name.length > 8 ? '${name.substring(0, 7)}…' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: AppText(
                      label,
                      fontSize: AppFontSizes.fz05,
                      color: AppColors.textSecondary(isDark),
                    ),
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
              final entry = entries[group.x.toInt()];
              return BarTooltipItem(
                '${entry.name}\n${entry.total.formatted}',
                TextStyle(color: AppColors.textPrimary(isDark), fontSize: AppFontSizes.fz06, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].total.toDouble(),
                  color: AppColors.accent,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
