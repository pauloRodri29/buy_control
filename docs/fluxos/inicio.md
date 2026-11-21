# Início (Dashboard)

[Fluxos](README.md) · [Relatórios](relatorios.md) · [Planos e limites](../configuracoes/planos-e-limites.md)

**Entrada:** primeira aba do `MainShell`. Recarrega toda vez que a aba é tocada.

1. **Resumo** (`GetDashboardSummary`), sempre do mês atual: total do mês, média diária,
   contagem de lançamentos e de Boxes ativas, Boxes com maior gasto e gastos recentes.
2. **Gráficos** (`GetDashboardCharts`), com filtros próprios (`DashboardFiltersSection`):
   período (este mês, mês passado, este ano ou personalizado), Box e categoria.
   - Evolução mensal: sempre visível.
   - Por categoria e por Box: exigem o módulo `dashboardCharts` (Essencial em diante);
     no Grátis aparece um `LockedFeatureCard` que leva aos planos.

**Dados atuais:** como nos Relatórios, contam **só lançamentos fechados**, pela data de
referência do Fechamento (`TransactionEntity.accountingDate`). As cores das séries vêm do
tema (`AppSemanticColors.chartSeries`), na ordem validada para daltonismo.

| Alterar | Fonte |
|---|---|
| Cartões de resumo | [get_dashboard_summary.dart](../../lib/features/dashboard/domain/usecases/get_dashboard_summary.dart) |
| Dados e filtros dos gráficos | [get_dashboard_charts.dart](../../lib/features/dashboard/domain/usecases/get_dashboard_charts.dart), [dashboard_controller.dart](../../lib/features/dashboard/presentation/controllers/dashboard_controller.dart) |
| Tela e bloqueio dos gráficos | [dashboard_page.dart](../../lib/features/dashboard/presentation/pages/dashboard_page.dart) |
| Gráficos (`fl_chart`) | [widgets do dashboard](../componentes/catalogo/modulo-dashboard.md) |
