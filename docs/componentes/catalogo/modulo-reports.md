# Módulo: Relatórios

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [report_evolution_chart](#report-evolution-chart)

<a id="report-evolution-chart"></a>

## report_evolution_chart

**Código:** [lib/features/reports/presentation/widgets/report_evolution_chart.dart](../../../lib/features/reports/presentation/widgets/report_evolution_chart.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### ReportEvolutionChart

Evolução mensal do total do relatório. Investimento de gráfico
deliberadamente pequeno aqui — a Dashboard é onde a análise visual
principal acontece; este componente só dá contexto de tendência.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const ReportEvolutionChart({super.key, required this.points});

// Tipos dos campos públicos declarados nesta classe.
  final List<ReportEvolutionPoint> points;
```

</details>

**Onde usar como referência:**

- [lib/features/reports/presentation/pages/reports_page.dart](../../../lib/features/reports/presentation/pages/reports_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
ReportEvolutionChart(points: r.evolution)
```

