import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class FilterChipOption {
  final String key;
  final String label;
  const FilterChipOption({required this.key, required this.label});
}

/// Linha horizontal de [ChoiceChip] nativos (estilo do `chipTheme`).
/// Tocar no chip selecionado desmarca (`onSelected(null)`).
class FilterChipsBar extends StatelessWidget {
  final List<FilterChipOption> options;
  final String? selectedKey;
  final ValueChanged<String?> onSelected;

  const FilterChipsBar({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final option = options[i];
          final selected = option.key == selectedKey;
          return ChoiceChip(
            label: Text(option.label),
            selected: selected,
            onSelected: (_) => onSelected(selected ? null : option.key),
          );
        },
      ),
    );
  }
}
