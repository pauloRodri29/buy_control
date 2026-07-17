import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/search_field_debounced.dart';
import 'package:buy_control/app/widgets/selectable_list_tile.dart';
import 'package:flutter/material.dart';

class MultiSelectOption {
  final String id;
  final String label;
  final String? subtitle;
  const MultiSelectOption({required this.id, required this.label, this.subtitle});
}

/// Bottom sheet de seleção múltipla reaproveitado pelos filtros de
/// categoria, tipo de produto e produto do relatório. Nenhum item
/// selecionado equivale a "sem filtro" (todos entram no relatório).
class MultiSelectPickerSheet extends StatefulWidget {
  final String title;
  final List<MultiSelectOption> options;
  final Set<String> initialSelectedIds;
  final bool showSearch;

  const MultiSelectPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.initialSelectedIds,
    this.showSearch = false,
  });

  static Future<Set<String>?> show(
    BuildContext context, {
    required String title,
    required List<MultiSelectOption> options,
    required Set<String> selectedIds,
    bool showSearch = false,
  }) {
    return AppBottomSheet.show<Set<String>>(
      context,
      height: MediaQuery.of(context).size.height * 0.85,
      child: MultiSelectPickerSheet(
        title: title,
        options: options,
        initialSelectedIds: selectedIds,
        showSearch: showSearch,
      ),
    );
  }

  @override
  State<MultiSelectPickerSheet> createState() => _MultiSelectPickerSheetState();
}

class _MultiSelectPickerSheetState extends State<MultiSelectPickerSheet> {
  late final Set<String> _selected = Set.of(widget.initialSelectedIds);
  String _query = '';

  List<MultiSelectOption> get _filtered {
    if (_query.isEmpty) return widget.options;
    final query = _query.toLowerCase();
    return widget.options.where((o) => o.label.toLowerCase().contains(query)).toList();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: AppText.title(widget.title, fontSize: AppFontSizes.fz09)),
            GestureDetector(
              onTap: () => setState(_selected.clear),
              child: AppText('Limpar', fontSize: AppFontSizes.fz06, color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.showSearch) ...[
          SearchFieldDebounced(hint: 'Buscar', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: AppSpacing.sm),
        ],
        Flexible(
          child: _filtered.isEmpty
              ? const EmptyStateView(title: 'Nenhum item encontrado')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final option = _filtered[i];
                    return SelectableListTile(
                      title: option.label,
                      subtitle: option.subtitle,
                      selected: _selected.contains(option.id),
                      onTap: () => _toggle(option.id),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText(
          _selected.isEmpty ? 'Todos incluídos (sem filtro)' : '${_selected.length} selecionado(s)',
          color: AppColors.textSecondary(isDark),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Aplicar', onPressed: () => Navigator.of(context).pop(_selected)),
      ],
    );
  }
}
