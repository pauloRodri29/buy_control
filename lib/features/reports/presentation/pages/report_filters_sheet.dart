import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/app/widgets/selectable_list_tile.dart';
import 'package:buy_control/features/reports/presentation/controllers/report_filter_state.dart';
import 'package:buy_control/features/reports/presentation/controllers/reports_controller.dart';
import 'package:buy_control/features/reports/presentation/controllers/saved_filter_preset.dart';
import 'package:buy_control/features/reports/presentation/pages/multi_select_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final _controller = Get.find<ReportsController>();
  ReportSide _side = ReportSide.a;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  final _presetNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = _controller.filterFor(_side);
    _minController = TextEditingController(text: _formatInput(f.minValue));
    _maxController = TextEditingController(text: _formatInput(f.maxValue));
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _presetNameController.dispose();
    super.dispose();
  }

  String _formatInput(double? value) => value == null ? '' : value.toStringAsFixed(2).replaceAll('.', ',');

  double? _parseInput(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _switchSide(ReportSide side) {
    setState(() {
      _side = side;
      final f = _controller.filterFor(side);
      _minController.text = _formatInput(f.minValue);
      _maxController.text = _formatInput(f.maxValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Expanded(child: AppText.title('Filtros', fontSize: AppFontSizes.fz09)),
                  GestureDetector(
                    onTap: () => controller.clearFilters(_side),
                    child: AppText('Limpar', fontSize: AppFontSizes.fz06, color: AppColors.accent),
                  ),
                ],
              ),
              if (controller.compareMode) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Lado A',
                        variant: _side == ReportSide.a ? AppButtonVariant.primary : AppButtonVariant.secondary,
                        onPressed: () => _switchSide(ReportSide.a),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Lado B',
                        variant: _side == ReportSide.b ? AppButtonVariant.primary : AppButtonVariant.secondary,
                        onPressed: () => _switchSide(ReportSide.b),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppText.subtitle('Período', color: AppColors.textSecondary(isDark)),
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
                    child: AppText(
                      f.periodPreset == ReportPeriodPreset.custom
                          ? 'Personalizado: ${f.periodLabel}'
                          : 'Ou escolha um período personalizado',
                      fontSize: AppFontSizes.fz06,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: f.customRange,
                      );
                      if (range != null) controller.setCustomRange(_side, range);
                    },
                    child: AppText('Personalizado', fontSize: AppFontSizes.fz06, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: AppText.subtitle('Boxes', color: AppColors.textSecondary(isDark))),
                  GestureDetector(
                    onTap: () => controller.selectAllBoxes(_side),
                    child: AppText('Selecionar todas', fontSize: AppFontSizes.fz06, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (controller.boxes.isEmpty)
                AppText('Nenhuma Box cadastrada.', color: AppColors.textSecondary(isDark))
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
                          subtitle: hintTotal == null ? null : 'Total histórico: ${hintTotal.total.formatted}',
                          selected: controller.isBoxSelected(_side, box.id),
                          onTap: () => controller.toggleBox(_side, box.id),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              _FilterLinkCard(
                label: 'Categoria',
                count: f.categoryIds.length,
                onTap: () async {
                  final result = await MultiSelectPickerSheet.show(
                    context,
                    title: 'Categorias',
                    options: controller.categories.map((c) => MultiSelectOption(id: c.id, label: c.name)).toList(),
                    selectedIds: f.categoryIds,
                  );
                  if (result != null) controller.toggleCategories(_side, result);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _FilterLinkCard(
                label: 'Tipo de produto',
                count: f.productTypeIds.length,
                onTap: () async {
                  final result = await MultiSelectPickerSheet.show(
                    context,
                    title: 'Tipos de produto',
                    options:
                        controller.productTypes.map((t) => MultiSelectOption(id: t.id, label: t.name)).toList(),
                    selectedIds: f.productTypeIds,
                  );
                  if (result != null) controller.toggleProductTypes(_side, result);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _FilterLinkCard(
                label: 'Produto',
                count: f.productIds.length,
                onTap: () async {
                  final result = await MultiSelectPickerSheet.show(
                    context,
                    title: 'Produtos',
                    options: controller.products.map((p) => MultiSelectOption(id: p.id, label: p.name)).toList(),
                    selectedIds: f.productIds,
                    showSearch: true,
                  );
                  if (result != null) controller.toggleProducts(_side, result);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppText.subtitle('Faixa de valor', color: AppColors.textSecondary(isDark)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _minController,
                      hint: 'Mínimo',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      onChanged: (v) => controller.setMinValue(_side, _parseInput(v)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _maxController,
                      hint: 'Máximo',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      onChanged: (v) => controller.setMaxValue(_side, _parseInput(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppText.subtitle('Salvar combinação frequente', color: AppColors.textSecondary(isDark)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: AppTextField(controller: _presetNameController, hint: 'Nome da combinação')),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: 'Salvar',
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
                      .map((preset) => _PresetChip(
                            preset: preset,
                            onApply: () => controller.applyPreset(preset, side: _side),
                            onRemove: () => controller.removePreset(preset),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Concluir', onPressed: () => Navigator.of(context).pop()),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: AppText(label, fontWeight: FontWeight.w600)),
          AppText(
            count == 0 ? 'Todas' : '$count selecionada(s)',
            fontSize: AppFontSizes.fz06,
            color: AppColors.textSecondary(isDark),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary(isDark)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppColors.surfaceVariant(isDark),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onApply,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(preset.name, fontSize: AppFontSizes.fz06),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onRemove,
                child: Icon(LucideIcons.x, size: 14, color: AppColors.textSecondary(isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
