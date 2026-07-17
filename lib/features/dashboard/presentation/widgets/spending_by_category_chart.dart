import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/dashboard/domain/usecases/get_dashboard_charts.dart';
import 'package:buy_control/features/dashboard/presentation/widgets/dashboard_chart_palette.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _maxSlices = 6;
const _othersId = '_others';

class SpendingByCategoryChart extends StatelessWidget {
  final List<NamedSpend> items;

  const SpendingByCategoryChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                child: AppText(
                  'Sem dados no período.',
                  fontSize: AppFontSizes.fz06,
                  color: AppColors.textSecondary(isDark),
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
                        color: _colorFor(entries[i], i, isDark),
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
                      decoration: BoxDecoration(color: _colorFor(entry, i, isDark), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppText(entry.name, fontSize: AppFontSizes.fz06, overflow: TextOverflow.ellipsis),
                    ),
                    AppText(
                      '${percent.toStringAsFixed(1)}%',
                      fontSize: AppFontSizes.fz06,
                      color: AppColors.textSecondary(isDark),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppText(entry.total.formatted, fontSize: AppFontSizes.fz06, fontWeight: FontWeight.w600),
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

  Color _colorFor(NamedSpend entry, int index, bool isDark) {
    return entry.id == _othersId ? DashboardChartPalette.other : DashboardChartPalette.slot(index, isDark);
  }
}
