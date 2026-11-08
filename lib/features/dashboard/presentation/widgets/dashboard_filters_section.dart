import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_date_picker.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subtitle('Período'),
        const SizedBox(height: AppSpacing.sm),
        FilterChipsBar(
          options: _periodOptions,
          selectedKey: controller.period.name,
          onSelected: (key) => _onPeriodSelected(context, key),
        ),
        if (controller.boxes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppText.subtitle('Box'),
          const SizedBox(height: AppSpacing.sm),
          FilterChipsBar(
            options: controller.boxes.map((b) => FilterChipOption(key: b.id, label: b.name)).toList(),
            selectedKey: controller.selectedBoxId,
            onSelected: controller.setBoxFilter,
          ),
        ],
        if (controller.categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppText.subtitle('Categoria'),
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
      final range = await AppDatePicker.showRange(
        context,
        title: 'Período personalizado',
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1),
        initialRange: controller.customRange,
        shortcuts: AppDatePicker.rangeShortcuts(),
      );
      if (range != null) await controller.setCustomRange(range);
      return;
    }
    await controller.setPeriod(DashboardPeriod.values.byName(key));
  }
}
