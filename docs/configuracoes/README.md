# Configurações e políticas centrais

[Índice](../README.md) · [Fluxos](../fluxos/README.md)

Altere a fonte indicada, não cada consumidor. Valores `const` exigem recompilação ou hot
restart; preferências do usuário (tema, idioma) são alteradas pelos controllers.

| Assunto | Documento | Fonte principal |
|---|---|---|
| Inicialização, estrutura de pastas, abas, navegação, DI | [Navegação e estrutura](navegacao.md) | `main.dart`, `AppBootstrap`, `InitialBinding`, `MainShell` |
| Hive boxes, chaves, seed, migração e limpeza | [Armazenamento](armazenamento.md) | `HiveBoxRegistry`, `AppMetaStore`, data sources |
| Planos, módulos, limites, itens inacessíveis, preços e cupons | [Planos e limites](planos-e-limites.md) | `PlanCatalog`, `QuotaGuard`, `AccessPolicy`, `PlanFeatures` |
| API do GitHub, timeouts e erros de rede | [Rede](rede.md) | `GithubBackupRemote` |
| Tema, cores, fonte, ícones, espaçamento, idioma, data/moeda | [Visual e idioma](visual-e-idioma.md) | `AppTheme`, `AppSemanticColors`, `AppBrand`, `AppLocale` |
| Como usar e combinar componentes | [Componentes](../componentes/README.md) | `lib/app/widgets/` |

## Catálogos de regras de negócio

| Regra | Onde modificar |
|---|---|
| Planos prontos: preço, limites e módulos | [plan_catalog.dart](../../lib/features/subscription/domain/plan_catalog.dart) |
| Recursos com limite e módulos (`ResourceKey`, `FeatureKey`) | [plan_keys.dart](../../lib/features/subscription/domain/entities/plan_keys.dart) |
| O que conta na cota (arquivados, padrões, quadros fechados) | [resource_inventory.dart](../../lib/features/subscription/domain/resource_inventory.dart) |
| Pesos do plano Personalizado | [custom_plan_pricing.dart](../../lib/features/subscription/domain/custom_plan_pricing.dart) |
| Cupons de teste | [local_coupon_repository.dart](../../lib/features/subscription/data/repositories/local_coupon_repository.dart) |
| Categorias, tipos e unidades padrão | [default_catalogs.dart](../../lib/core/catalog/default_catalogs.dart) |
| Tipos de promoção por item | [discount_rule.dart](../../lib/features/transactions/domain/entities/discount_rule.dart) |
| Ordenação de lançamentos e Boxes | [transaction_sort.dart](../../lib/features/transactions/domain/usecases/transaction_sort.dart), [boxes_controller.dart](../../lib/features/boxes/presentation/controllers/boxes_controller.dart) |
| Períodos do relatório e do Início | [report_filter_state.dart](../../lib/features/reports/presentation/controllers/report_filter_state.dart), [dashboard_controller.dart](../../lib/features/dashboard/presentation/controllers/dashboard_controller.dart) |
| Motivos de item não comprado | [finish_plan_board_sheet.dart](../../lib/features/planning/presentation/widgets/finish_plan_board_sheet.dart) |
| Layout da etiqueta de balança | [barcode_parser.dart](../../lib/core/barcode/barcode_parser.dart) |
| Coleções do backup | [backup_collections.dart](../../lib/features/backup/domain/entities/backup_collections.dart) |
| Escopos de "Limpar dados" | [clear_app_data.dart](../../lib/features/settings/domain/usecases/clear_app_data.dart) |
| Versão do schema (migração) | [migration_runner.dart](../../lib/app/bootstrap/migration_runner.dart) (`currentSchemaVersion`) |
| Versão do formato de backup | [export_backup.dart](../../lib/features/backup/domain/usecases/export_backup.dart) (`backupFormatVersion`) |
