# Filtros e seleção

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [filter_chips_bar](#filter-chips-bar)
- [selectable_list_tile](#selectable-list-tile)

<a id="filter-chips-bar"></a>

## filter_chips_bar

**Código:** [lib/app/widgets/filter_chips_bar.dart](../../../lib/app/widgets/filter_chips_bar.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### FilterChipOption

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const FilterChipOption({required this.key, required this.label});

// Tipos dos campos públicos declarados nesta classe.
  final String key;
  final String label;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/boxes/presentation/pages/box_detail_page.dart](../../../lib/features/boxes/presentation/pages/box_detail_page.dart)
- [lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart](../../../lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
FilterChipOption(key: 'date', label: 'boxes.recent')
```

### FilterChipsBar

Linha horizontal de [ChoiceChip] nativos (estilo do `chipTheme`).
Tocar no chip selecionado desmarca (`onSelected(null)`).

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const FilterChipsBar({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

// Tipos dos campos públicos declarados nesta classe.
  final List<FilterChipOption> options;
  final String? selectedKey;
  final ValueChanged<String?> onSelected;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/boxes/presentation/pages/box_detail_page.dart](../../../lib/features/boxes/presentation/pages/box_detail_page.dart)
- [lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart](../../../lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
FilterChipsBar(
                        options: _sortOptions,
                        selectedKey: _sortKey(controller.sort),
                        onSelected: (key) => controller.setSort(_sortFromKey(key)),
                      )
```

<a id="selectable-list-tile"></a>

## selectable_list_tile

**Código:** [lib/app/widgets/selectable_list_tile.dart](../../../lib/app/widgets/selectable_list_tile.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### SelectableListTile

Item de lista selecionável ([ListTile] nativo com `selected`), usado em
seleções múltiplas como os filtros dos relatórios.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const SelectableListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.selected,
    required this.onTap,
  });

// Tipos dos campos públicos declarados nesta classe.
  final String title;
  final String? subtitle;
  final String? trailingText;
  final bool selected;
  final VoidCallback onTap;
```

</details>

**Onde usar como referência:**

- [lib/features/reports/presentation/pages/multi_select_picker_sheet.dart](../../../lib/features/reports/presentation/pages/multi_select_picker_sheet.dart)
- [lib/features/reports/presentation/pages/report_filters_sheet.dart](../../../lib/features/reports/presentation/pages/report_filters_sheet.dart)
- [lib/features/transactions/presentation/pages/product_picker_sheet.dart](../../../lib/features/transactions/presentation/pages/product_picker_sheet.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
SelectableListTile(
                      title: option.label,
                      subtitle: option.subtitle,
                      selected: _selected.contains(option.id),
                      onTap: () => _toggle(option.id),
                    )
```

