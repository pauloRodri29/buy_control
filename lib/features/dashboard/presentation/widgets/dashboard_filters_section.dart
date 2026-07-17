import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';

const _periodOptions = [
  FilterChipOption(key: 'thisMonth', label: 'Este mês'),
  FilterChipOption(key: 'lastMonth', label: 'Mês anterior'),
  FilterChipOption(key: 'thisYear', label: 'Este ano'),
  FilterChipOption(key: 'custom', label: 'Personalizado'),
];

class DashboardFiltersSection extends StatelessWidget {
  final DashboardController controller;

  const DashboardFiltersSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subtitle('Período', color: AppColors.textSecondary(isDark)),
        const SizedBox(height: AppSpacing.sm),
        FilterChipsBar(
          options: _periodOptions,
          selectedKey: controller.period.name,
          onSelected: (key) => _onPeriodSelected(context, key),
        ),
        if (controller.boxes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppText.subtitle('Box', color: AppColors.textSecondary(isDark)),
          const SizedBox(height: AppSpacing.sm),
          FilterChipsBar(
            options: controller.boxes.map((b) => FilterChipOption(key: b.id, label: b.name)).toList(),
            selectedKey: controller.selectedBoxId,
            onSelected: controller.setBoxFilter,
          ),
        ],
        if (controller.categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppText.subtitle('Categoria', color: AppColors.textSecondary(isDark)),
          const SizedBox(height: AppSpacing.sm),
          FilterChipsBar(
            options: controller.categories.map((c) => FilterChipOption(key: c.id, label: c.name)).toList(),
            selectedKey: controller.selectedCategoryId,
            onSelected: controller.setCategoryFilter,
          ),
        ],
      ],
    );
  }

  Future<void> _onPeriodSelected(BuildContext context, String? key) async {
    if (key == null) return;
    if (key == 'custom') {
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1),
        initialDateRange: controller.customRange,
      );
      if (range != null) await controller.setCustomRange(range);
      return;
    }
    await controller.setPeriod(DashboardPeriod.values.byName(key));
  }
}
