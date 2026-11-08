import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/reports/domain/usecases/get_consolidated_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _monthAbbreviations = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

/// Evolução mensal do total do relatório. Investimento de gráfico
/// deliberadamente pequeno aqui — a Dashboard é onde a análise visual
/// principal acontece; este componente só dá contexto de tendência.
class ReportEvolutionChart extends StatelessWidget {
  final List<ReportEvolutionPoint> points;

  const ReportEvolutionChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Evolução mensal'),
          const SizedBox(height: AppSpacing.md),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: AppText.small(
                  'Sem dados no período.',
                  
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else if (points.length == 1)
            _EvolutionRow(point: points.first)
          else
            SizedBox(height: 180, child: _Chart(points: points)),
        ],
      ),
    );
  }
}

class _EvolutionRow extends StatelessWidget {
  final ReportEvolutionPoint point;

  const _EvolutionRow({required this.point});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          '${_monthAbbreviations[point.month.month - 1]}/${point.month.year}',
          color: context.colors.onSurfaceVariant,
        ),
        AppText(point.total.formatted, fontWeight: FontWeight.w600),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  final List<ReportEvolutionPoint> points;

  const _Chart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (max, p) {
      final value = p.total.toDouble();
      return value > max ? value : max;
    });
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
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
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => context.colors.surfaceContainerHighest,
            getTooltipItems: (spots) => spots.map((spot) {
              final point = points[spot.x.toInt()];
              return LineTooltipItem(
                point.total.formatted,
                context.text.labelMedium!.copyWith(color: context.colors.onSurface, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].total.toDouble())],
            isCurved: true,
            color: context.colors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: context.colors.primary.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}
