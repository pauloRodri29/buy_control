import 'package:get/get.dart';
import 'package:buy_control/app/theme/theme_context.dart';
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
    final entries = (items.where((e) => !e.total.isZero).toList()
          ..sort((a, b) => b.total.cents.compareTo(a.total.cents)))
        .take(_maxBars)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle('dashboard.spendingBox'.tr),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: AppText.small(
                  'common.noDataPeriod'.tr,
                  
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else
            SizedBox(height: 220, child: _Chart(entries: entries)),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<NamedSpend> entries;

  const _Chart({required this.entries});

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
                    child: AppText.caption(
                      label,
                      
                      color: context.colors.onSurfaceVariant,
                    ),
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
              final entry = entries[group.x.toInt()];
              return BarTooltipItem(
                '${entry.name}\n${entry.total.formatted}',
                context.text.labelMedium!.copyWith(color: context.colors.onSurface, fontWeight: FontWeight.w600),
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
                  color: context.colors.primary,
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
