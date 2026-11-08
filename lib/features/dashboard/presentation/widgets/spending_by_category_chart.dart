import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _maxSlices = 6;
const _othersId = '_others';

class SpendingByCategoryChart extends StatelessWidget {
  final List<NamedSpend> items;

  const SpendingByCategoryChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries(items);
    final total = entries.fold(Money.zero, (sum, e) => sum + e.total);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Gastos por categoria'),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: AppText.small(
                  'Sem dados no período.',
                  
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].total.toDouble(),
                        color: _colorFor(context, entries[i], i),
                        showTitle: false,
                        radius: 48,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(entries.length, (i) {
              final entry = entries[i];
              final percent = total.cents == 0 ? 0.0 : (entry.total.cents / total.cents) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _colorFor(context, entry, i), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppText.small(entry.name,  overflow: TextOverflow.ellipsis),
                    ),
                    AppText.small(
                      '${percent.toStringAsFixed(1)}%',
                      
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppText.small(entry.total.formatted,  fontWeight: FontWeight.w600),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<NamedSpend> _buildEntries(List<NamedSpend> items) {
    final nonZero = items.where((e) => !e.total.isZero).toList()
      ..sort((a, b) => b.total.cents.compareTo(a.total.cents));
    if (nonZero.length <= _maxSlices) return nonZero;

    final visible = nonZero.take(_maxSlices).toList();
    final othersTotal = nonZero.skip(_maxSlices).fold(Money.zero, (sum, e) => sum + e.total);
    return [...visible, NamedSpend(id: _othersId, name: 'Outros', total: othersTotal)];
  }

  Color _colorFor(BuildContext context, NamedSpend entry, int index) {
    return entry.id == _othersId ? context.semantic.chartOther : context.semantic.chart(index);
  }
}
