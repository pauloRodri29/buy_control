# Relatórios

[Fluxos](README.md) · [Fechamento](fechamento.md) · [Planejamento](planejamento.md) · [Planos e limites](../configuracoes/planos-e-limites.md)

**Entrada:** Mais → Relatórios.

1. **Filtros** (`ReportFiltersSheet`): período (hoje, últimos 7 dias, mês atual, mês
   anterior, ano atual ou personalizado). Filtros avançados — várias Boxes, categoria, tipo,
   produto e faixa de valor — exigem `reportsAdvanced` (Essencial em diante).
2. **Indicadores** (`GetConsolidatedReport`): total, médias por Box/dia, contagens,
   destaques (Box, categoria, produto, produto mais comprado), evolução mensal e tabela de
   produtos.
3. **Comparação A × B** (exige `reportsCompare`, Pro): cada lado com seus filtros,
   indicadores lado a lado.
4. **Filtros salvos:** nomear e salvar a combinação (`SavedFilterPreset`, box
   `report_presets`); reaparecem nas próximas sessões. Sem limite por plano.
5. **Exportar** (`ReportExportSheet`, exige `exportPdf`, Essencial em diante):

| Opção | Estado |
|---|---|
| PDF | gera o arquivo e salva no armazenamento do app |
| Compartilhar / Imprimir | mesmo PDF, folha nativa (`printing`) |
| CSV | não implementado (`NotImplementedFailure`, "em breve") |
| Backup em JSON | não implementado; o backup completo fica em [Backup](backup.md) |

## Regra central

Dos lançamentos das Boxes, o relatório considera **só os fechados**, pela data de
referência do Fechamento. Um relatório gerado hoje continua igual amanhã.

**Planejamento no relatório:** um card mostra os itens comprados no período (por quadro),
a previsão dos pendentes e a comparação com as metas. Os comprados entram no total e na
evolução mensal pela data da compra. Com filtro de Box, categoria, tipo ou produto, o
Planejamento fica de fora (os itens dos quadros não têm essas informações).

| Alterar | Fonte |
|---|---|
| Cálculo | [get_consolidated_report.dart](../../lib/features/reports/domain/usecases/get_consolidated_report.dart) |
| Estado dos filtros e presets de período | [report_filter_state.dart](../../lib/features/reports/presentation/controllers/report_filter_state.dart) |
| Filtros salvos | [report_preset_repository.dart](../../lib/features/reports/data/repositories/report_preset_repository.dart) |
| PDF e formatos | [app_report_exporter.dart](../../lib/features/reports/data/exporters/app_report_exporter.dart), [pdf_report_builder.dart](../../lib/features/reports/data/exporters/pdf_report_builder.dart) |
| Bloqueios por plano | [reports_page.dart](../../lib/features/reports/presentation/pages/reports_page.dart), [report_filters_sheet.dart](../../lib/features/reports/presentation/pages/report_filters_sheet.dart), [report_export_sheet.dart](../../lib/features/reports/presentation/pages/report_export_sheet.dart) |
| Testes | [get_consolidated_report_test.dart](../../test/features/reports/get_consolidated_report_test.dart) |
