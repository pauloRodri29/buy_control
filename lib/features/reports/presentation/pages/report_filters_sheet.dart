import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_date_picker.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/app/widgets/selectable_list_tile.dart';
import 'package:buy_control/features/reports/presentation/controllers/report_filter_state.dart';
import 'package:buy_control/features/reports/presentation/controllers/reports_controller.dart';
import 'package:buy_control/features/reports/presentation/controllers/saved_filter_preset.dart';
import 'package:buy_control/features/reports/presentation/pages/multi_select_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/presentation/plan_features.dart';

/// Bottom sheet único que concentra todos os filtros do relatório: período,
/// Boxes, categoria, tipo de produto, produto e faixa de valor. Quando o
/// modo de comparação está ativo, um seletor de Lado A/B permite editar
/// os dois conjuntos de filtros sem duplicar esta UI.
class ReportFiltersSheet extends StatefulWidget {
  const ReportFiltersSheet({super.key});

  @override
  State<ReportFiltersSheet> createState() => _ReportFiltersSheetState();
}

class _ReportFiltersSheetState extends State<ReportFiltersSheet> {
  ReportSide _side = ReportSide.a;
  final _presetNameController = TextEditingController();

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
  }

  void _switchSide(ReportSide side) {
    setState(() => _side = side);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReportsController>(
      builder: (controller) {
        final f = controller.filterFor(_side);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: AppText.heading('reports.filters'.tr)),
                  GestureDetector(
                    onTap: () => controller.clearFilters(_side),
                    child: AppText.small('common.clear'.tr, color: context.colors.primary),
                  ),
                ],
              ),
              if (controller.compareMode) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'reports.side'.tr,
                        variant: _side == ReportSide.a ? AppButtonVariant.primary : AppButtonVariant.secondary,
                        onPressed: () => _switchSide(ReportSide.a),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'reports.sideB'.tr,
                        variant: _side == ReportSide.b ? AppButtonVariant.primary : AppButtonVariant.secondary,
                        onPressed: () => _switchSide(ReportSide.b),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppText.subtitle('common.period'.tr),
              const SizedBox(height: AppSpacing.sm),
              FilterChipsBar(
                options: ReportPeriodPreset.values
                    .where((p) => p != ReportPeriodPreset.custom)
                    .map((p) => FilterChipOption(key: p.name, label: p.label))
                    .toList(),
                selectedKey: f.periodPreset == ReportPeriodPreset.custom ? null : f.periodPreset.name,
                onSelected: (key) {
                  if (key == null) return;
                  controller.setPeriodPreset(_side, ReportPeriodPreset.values.firstWhere((p) => p.name == key));
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppText.small(
                      f.periodPreset == ReportPeriodPreset.custom
                          ? 'reports.customPeriodLabel'.trParams({'periodLabel': f.periodLabel})
                          : 'reports.chooseCustomPeriod'.tr,

                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final range = await AppDatePicker.showRange(
                        context,
                        title: 'common.customPeriod'.tr,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialRange: f.customRange,
                        shortcuts: AppDatePicker.rangeShortcuts(),
                      );
                      if (range != null) controller.setCustomRange(_side, range);
                    },
                    child: AppText.small('common.custom'.tr, color: context.colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!PlanFeatures.has(FeatureKey.reportsAdvanced))
                LockedFeatureCard(
                  feature: FeatureKey.reportsAdvanced,
                  title: 'reports.filterBoxCategoryProductValue'.tr,
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: AppText.subtitle('common.boxes'.tr)),
                    GestureDetector(
                      onTap: () => controller.selectAllBoxes(_side),
                      child: AppText.small('reports.selectAll'.tr, color: context.colors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (controller.boxes.isEmpty)
                  AppText('reports.noBoxesRegistered'.tr, color: context.colors.onSurfaceVariant)
                else
                  Builder(
                    builder: (_) {
                      final hintTotalsById = {for (final b in controller.boxTotals) b.boxId: b};
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.boxes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final box = controller.boxes[i];
                          final hintTotal = hintTotalsById[box.id];
                          return SelectableListTile(
                            title: box.name,
                            subtitle: hintTotal == null ? null : 'reports.allTimeTotalAmount'.trParams({'formatted': hintTotal.total.formatted}),
                            selected: controller.isBoxSelected(_side, box.id),
                            onTap: () => controller.toggleBox(_side, box.id),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                _FilterLinkCard(
                  label: 'common.category'.tr,
                  count: f.categoryIds.length,
                  onTap: () async {
                    final result = await MultiSelectPickerSheet.show(
                      context,
                      title: 'common.categories'.tr,
                      options: controller.categories.map((c) => MultiSelectOption(id: c.id, label: c.name)).toList(),
                      selectedIds: f.categoryIds,
                    );
                    if (result != null) controller.toggleCategories(_side, result);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _FilterLinkCard(
                  label: 'common.productType'.tr,
                  count: f.productTypeIds.length,
                  onTap: () async {
                    final result = await MultiSelectPickerSheet.show(
                      context,
                      title: 'common.productTypes2'.tr,
                      options: controller.productTypes.map((t) => MultiSelectOption(id: t.id, label: t.name)).toList(),
                      selectedIds: f.productTypeIds,
                    );
                    if (result != null) controller.toggleProductTypes(_side, result);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _FilterLinkCard(
                  label: 'common.product'.tr,
                  count: f.productIds.length,
                  onTap: () async {
                    final result = await MultiSelectPickerSheet.show(
                      context,
                      title: 'common.products'.tr,
                      options: controller.products.map((p) => MultiSelectOption(id: p.id, label: p.name)).toList(),
                      selectedIds: f.productIds,
                      showSearch: true,
                    );
                    if (result != null) controller.toggleProducts(_side, result);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppText.subtitle('reports.valueRange'.tr),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppMoneyField(
                        key: ValueKey('min-$_side'),
                        initialValue: f.minValue,
                        hint: 'reports.minimum'.tr,
                        onChanged: (money) => controller.setMinValue(_side, money.isZero ? null : money),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppMoneyField(
                        key: ValueKey('max-$_side'),
                        initialValue: f.maxValue,
                        hint: 'reports.maximum'.tr,
                        onChanged: (money) => controller.setMaxValue(_side, money.isZero ? null : money),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppText.subtitle('reports.saveFrequentCombination'.tr),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(controller: _presetNameController, hint: 'reports.combinationName'.tr),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'common.save'.tr,
                      expanded: false,
                      onPressed: () {
                        controller.savePreset(_presetNameController.text);
                        _presetNameController.clear();
                      },
                    ),
                  ],
                ),
                if (controller.savedPresets.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: controller.savedPresets
                        .map(
                          (preset) => _PresetChip(
                            preset: preset,
                            onApply: () => controller.applyPreset(preset, side: _side),
                            onRemove: () => controller.removePreset(preset),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'common.done'.tr, onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        );
      },
    );
  }
}

class _FilterLinkCard extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _FilterLinkCard({required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: AppText(label, fontWeight: FontWeight.w600)),
          AppText.small(count == 0 ? 'reports.all'.tr : 'reports.selectedCount'.trParams({'count': '$count'}), color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Icon(Symbols.chevron_right, size: 18, color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final SavedFilterPreset preset;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _PresetChip({required this.preset, required this.onApply, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onApply,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.small(preset.name),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Symbols.close, size: 14, color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
