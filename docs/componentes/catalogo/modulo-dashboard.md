# Módulo: Início (Dashboard)

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [dashboard_filters_section](#dashboard-filters-section)
- [monthly_evolution_chart](#monthly-evolution-chart)
- [spending_by_box_chart](#spending-by-box-chart)
- [spending_by_category_chart](#spending-by-category-chart)

<a id="dashboard-filters-section"></a>

## dashboard_filters_section

**Código:** [lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart](../../../lib/features/dashboard/presentation/widgets/dashboard_filters_section.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### DashboardFiltersSection

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const DashboardFiltersSection({super.key, required this.controller});

// Tipos dos campos públicos declarados nesta classe.
  final DashboardController controller;
```

</details>

**Onde usar como referência:**

- [lib/features/dashboard/presentation/pages/dashboard_page.dart](../../../lib/features/dashboard/presentation/pages/dashboard_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
DashboardFiltersSection(controller: controller)
```

<a id="monthly-evolution-chart"></a>

## monthly_evolution_chart

**Código:** [lib/features/dashboard/presentation/widgets/monthly_evolution_chart.dart](../../../lib/features/dashboard/presentation/widgets/monthly_evolution_chart.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### MonthlyEvolutionChart

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const MonthlyEvolutionChart({super.key, required this.points});

// Tipos dos campos públicos declarados nesta classe.
  final List<MonthlyPoint> points;
```

</details>

**Onde usar como referência:**

- [lib/features/dashboard/presentation/pages/dashboard_page.dart](../../../lib/features/dashboard/presentation/pages/dashboard_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
MonthlyEvolutionChart(points: charts.monthlyEvolution)
```

<a id="spending-by-box-chart"></a>

## spending_by_box_chart

**Código:** [lib/features/dashboard/presentation/widgets/spending_by_box_chart.dart](../../../lib/features/dashboard/presentation/widgets/spending_by_box_chart.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### SpendingByBoxChart

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const SpendingByBoxChart({super.key, required this.items});

// Tipos dos campos públicos declarados nesta classe.
  final List<NamedSpend> items;
```

</details>

**Onde usar como referência:**

- [lib/features/dashboard/presentation/pages/dashboard_page.dart](../../../lib/features/dashboard/presentation/pages/dashboard_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
SpendingByBoxChart(items: charts.spendingByBox)
```

<a id="spending-by-category-chart"></a>

## spending_by_category_chart

**Código:** [lib/features/dashboard/presentation/widgets/spending_by_category_chart.dart](../../../lib/features/dashboard/presentation/widgets/spending_by_category_chart.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### SpendingByCategoryChart

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const SpendingByCategoryChart({super.key, required this.items});

// Tipos dos campos públicos declarados nesta classe.
  final List<NamedSpend> items;
```

</details>

**Onde usar como referência:**

- [lib/features/dashboard/presentation/pages/dashboard_page.dart](../../../lib/features/dashboard/presentation/pages/dashboard_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
SpendingByCategoryChart(items: charts.spendingByCategory)
```

