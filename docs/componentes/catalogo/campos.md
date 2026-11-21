# Campos e seletores

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [app_date_picker](#app-date-picker)
- [app_dropdown](#app-dropdown)
- [app_money_field](#app-money-field)
- [app_text_field](#app-text-field)
- [search_field_debounced](#search-field-debounced)

<a id="app-date-picker"></a>

## app_date_picker

**Código:** [lib/app/widgets/app_date_picker.dart](../../../lib/app/widgets/app_date_picker.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppDateShortcut

Atalho exibido acima do calendário ("Hoje", "Fim do mês"...).

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppDateShortcut(this.label, this.date);

AppDateShortcut('common.today'.tr, today);

AppDateShortcut('common.endMonth'.tr, DateTime(today.year, today.month + 1, 0));

AppDateShortcut('common.nextMonth'.tr, DateTime(today.year, today.month + 2, 0));

AppDateShortcut('common.endYear'.tr, DateTime(today.year, 12, 31));

AppDateShortcut('common.today'.tr, today);

AppDateShortcut('common.yesterday'.tr, today.subtract(const Duration(days: 1)));

AppDateShortcut('common.endLastMonth'.tr, DateTime(today.year, today.month, 0));

// Tipos dos campos públicos declarados nesta classe.
  final String label;
  final DateTime date;
```

</details>

**Integração:** nenhuma chamada direta encontrada fora deste arquivo. Pode ser usado só por herança, `static` ou dentro do próprio arquivo; confira a fonte antes de adotar ou remover.

### AppDateRangeShortcut

Atalho de intervalo ("Este mês", "Últimos 30 dias"...).

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppDateRangeShortcut(this.label, this.range);

AppDateRangeShortcut('common.last7Days'.tr, DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today));

AppDateRangeShortcut('common.last30Days'.tr, DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today));

AppDateRangeShortcut('common.month'.tr, DateTimeRange(start: DateTime(today.year, today.month, 1), end: today));

AppDateRangeShortcut(
        'common.lastMonth'.tr,
        DateTimeRange(start: DateTime(today.year, today.month - 1, 1), end: DateTime(today.year, today.month, 0)),
      );

// Tipos dos campos públicos declarados nesta classe.
  final String label;
  final DateTimeRange range;
```

</details>

**Integração:** nenhuma chamada direta encontrada fora deste arquivo. Pode ser usado só por herança, `static` ou dentro do próprio arquivo; confira a fonte antes de adotar ou remover.

### AppDatePicker

Seletor de data do app, em bottom sheet, no lugar do `showDatePicker`
nativo. Usa `table_calendar` com o visual do design system (cores,
raios, tipografia) e suporta data única ou intervalo.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
static List<AppDateShortcut> futureShortcuts();

static List<AppDateShortcut> recentShortcuts();

static List<AppDateRangeShortcut> rangeShortcuts();

static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String confirmLabel = 'common.confirm',
    List<AppDateShortcut> shortcuts = const [],
  });

static Future<DateTimeRange?> showRange(
    BuildContext context, {
    required String title,
    DateTimeRange? initialRange,
    required DateTime firstDate,
    required DateTime lastDate,
    String confirmLabel = 'common.apply',
    List<AppDateRangeShortcut> shortcuts = const [],
  });

```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/box_detail_page.dart](../../../lib/features/boxes/presentation/pages/box_detail_page.dart)
- [lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart](../../../lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart)
- [lib/features/planning/presentation/pages/plan_board_history_page.dart](../../../lib/features/planning/presentation/pages/plan_board_history_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppDatePicker.show(
      context,
      title: 'boxes.closingReferenceDate'.tr,
      confirmLabel: 'common.continue'.tr,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      shortcuts: AppDatePicker.recentShortcuts(),
    )
```

<a id="app-dropdown"></a>

## app_dropdown

**Código:** [lib/app/widgets/app_dropdown.dart](../../../lib/app/widgets/app_dropdown.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppDropdownOption

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppDropdownOption({required this.value, required this.label});

// Tipos dos campos públicos declarados nesta classe.
  final T value;
  final String label;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/widgets/plan_item_form_sheet.dart](../../../lib/features/planning/presentation/widgets/plan_item_form_sheet.dart)
- [lib/features/products/presentation/widgets/product_form_sheet.dart](../../../lib/features/products/presentation/widgets/product_form_sheet.dart)
- [lib/features/transactions/presentation/pages/item_details_step.dart](../../../lib/features/transactions/presentation/pages/item_details_step.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppDropdownOption(value: _noBoard, label: 'common.noBoard'.tr)
```

### AppDropdown

[DropdownButtonFormField] nativo com rótulo acima, no mesmo visual do
`AppTextField` (decoração vinda do `inputDecorationTheme`).

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
    this.label,
    this.errorText,
  });

// Tipos dos campos públicos declarados nesta classe.
  final List<AppDropdownOption<T>> options;
  final T? value;
  final String? hint;
  final String? label;
  final String? errorText;
  final ValueChanged<T?> onChanged;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/widgets/plan_item_form_sheet.dart](../../../lib/features/planning/presentation/widgets/plan_item_form_sheet.dart)
- [lib/features/products/presentation/widgets/product_form_sheet.dart](../../../lib/features/products/presentation/widgets/product_form_sheet.dart)
- [lib/features/transactions/presentation/pages/item_details_step.dart](../../../lib/features/transactions/presentation/pages/item_details_step.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppDropdown<String>(
            label: 'planning.board'.tr,
            value: boardId,
            options: [
              AppDropdownOption(value: _noBoard, label: 'common.noBoard'.tr),
              for (final b in boards)
                AppDropdownOption(value: b.id, label: '${b.title} · ${DateTimeFormatter.ddMMyyyy(b.targetDate)}'),
            ],
            onChanged: (v) => setState(() => boardId = v ?? _noBoard),
          )
```

<a id="app-money-field"></a>

## app_money_field

**Código:** [lib/app/widgets/app_money_field.dart](../../../lib/app/widgets/app_money_field.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppMoneyField

Campo de valor monetário reutilizável: formata como moeda em tempo
real (`MoneyInputFormatter`) e sempre expõe/recebe [Money], nunca
String/double crus — elimina o parser manual duplicado em cada tela
que pede um valor em reais.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppMoneyField({
    super.key,
    this.initialValue,
    this.label,
    this.hint = 'R\$ 0,00',
    this.errorText,
    required this.onChanged,
  });

// Tipos dos campos públicos declarados nesta classe.
  final Money? initialValue;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<Money> onChanged;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/plan_board_history_page.dart](../../../lib/features/planning/presentation/pages/plan_board_history_page.dart)
- [lib/features/planning/presentation/widgets/finish_plan_board_sheet.dart](../../../lib/features/planning/presentation/widgets/finish_plan_board_sheet.dart)
- [lib/features/planning/presentation/widgets/plan_board_form_sheet.dart](../../../lib/features/planning/presentation/widgets/plan_board_form_sheet.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppMoneyField(
            label: 'planning.amountPaid'.tr,
            initialValue: widget.item.value,
            onChanged: (v) => paid = v,
          )
```

<a id="app-text-field"></a>

## app_text_field

**Código:** [lib/app/widgets/app_text_field.dart](../../../lib/app/widgets/app_text_field.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppTextField

[TextField] nativo com rótulo acima do campo. Fundo, bordas, cores e
tipografia vêm do `inputDecorationTheme`/`textTheme`.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefix,
    this.suffix,
    this.errorText,
  });

// Tipos dos campos públicos declarados nesta classe.
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
```

</details>

**Onde usar como referência:**

- [lib/app/widgets/app_money_field.dart](../../../lib/app/widgets/app_money_field.dart)
- [lib/features/auth/presentation/pages/login_page.dart](../../../lib/features/auth/presentation/pages/login_page.dart)
- [lib/features/auth/presentation/pages/profile_page.dart](../../../lib/features/auth/presentation/pages/profile_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppTextField(
      controller: _controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      keyboardType: TextInputType.number,
      inputFormatters: [MoneyInputFormatter()],
      onChanged: (value) => widget.onChanged(MoneyInputFormatter.parse(value)),
    )
```

<a id="search-field-debounced"></a>

## search_field_debounced

**Código:** [lib/app/widgets/search_field_debounced.dart](../../../lib/app/widgets/search_field_debounced.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### SearchFieldDebounced

Campo de busca nativo ([TextField]) que só avisa a mudança depois de
uma pausa na digitação. Sem borda em repouso; ao focar, usa a borda de
foco do `inputDecorationTheme`.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const SearchFieldDebounced({
    super.key,
    this.hint = 'common.search',
    required this.onChanged,
    this.debounce = AppDurations.searchDebounce,
  });

// Tipos dos campos públicos declarados nesta classe.
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/boxes/presentation/pages/box_detail_page.dart](../../../lib/features/boxes/presentation/pages/box_detail_page.dart)
- [lib/features/products/presentation/pages/products_page.dart](../../../lib/features/products/presentation/pages/products_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
SearchFieldDebounced(hint: 'boxes.searchBox'.tr, onChanged: controller.search)
```

