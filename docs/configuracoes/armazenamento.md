# Armazenamento local

[Configurações](README.md) · [Backup](../fluxos/backup.md) · [Navegação](navegacao.md)

Tudo fica no aparelho, em **Hive** (`hive_flutter`). Não há servidor; o único dado que sai
do aparelho é o [backup no GitHub](../fluxos/backup.md), quando o usuário configura.

## Boxes

Os nomes ficam num catálogo único, [HiveBoxRegistry](../../lib/core/database/hive_box_registry.dart),
que também abre todas as boxes uma vez no bootstrap (`initHive`). Não use `Hive.openBox`
espalhado: box nova = constante nova + entrada em `_allBoxNames`.

| Box | Conteúdo | Chave | No backup? |
|---|---|---|---|
| `boxes` | `BoxModel` | id | sim |
| `transactions` | `TransactionModel` (com os itens) | id | sim |
| `box_closures` | `BoxClosureModel` | id | sim |
| `products` | `ProductModel` | id | sim |
| `categories` | `CategoryModel` | id | sim |
| `product_types` | `ProductTypeModel` | id | sim |
| `units` | `UnitModel` | id | sim |
| `plan_boards` | `PlanBoardModel` | id | sim |
| `plan_items` | `PlanItemModel` | id | sim |
| `report_presets` | filtros de relatório salvos (`SavedFilterPreset`) | nome | não |
| `auth_session` | perfis (`UserModel`) + `currentUserId` | id do usuário | não |
| `subscription` | assinatura por usuário + `coupons:<userId>` (cupons usados) | id do usuário | não |
| `app_meta` | metadados e preferências (abaixo) | chave fixa | não |
| `box_buy_control` | formato **legado**, só lido pela migração | — | não |
| `backup_pre_migration_v2` | cópia crua dos dados legados (`boxList_raw`), guardada pela migração | — | não |

<a id="auth_session"></a>
Os dados de domínio **não** são separados por usuário: só `subscription` (e os cupons) usa
o id do usuário na chave.

## Registros com chave fixa (`app_meta`)

| Chave | Conteúdo | Fonte |
|---|---|---|
| `schemaVersion` | versão do schema aplicada pela migração | [app_meta_store.dart](../../lib/core/database/app_meta_store.dart) |
| `defaultsSeeded` | se os catálogos padrão já foram criados | mesma fonte |
| `themeMode` | `system`, `light` ou `dark` (`null` = segue o sistema) | mesma fonte |
| `locale` | `pt_BR` ou `en_US` (`null` = segue o aparelho) | mesma fonte |
| `backup.github.owner`, `backup.github.repo`, `backup.github.path` | repositório do backup | [backup_settings_store.dart](../../lib/features/backup/data/backup_settings_store.dart) |
| `backup.log` | últimas 30 operações de backup | mesma fonte |

O **token do GitHub** não fica no Hive: vai para o armazenamento seguro do sistema
(`flutter_secure_storage`, chave `backup.github.token`).

## Arquivos

| Arquivo | Onde | Fonte |
|---|---|---|
| `gastolog_pre_import_snapshot.json` + `.meta.json` | documentos do app | cópia antes da última importação ([safety_snapshot_store.dart](../../lib/features/backup/data/safety_snapshot_store.dart)) |
| `gastolog_backup_<data-hora>.json` | documentos do app | backup exportado para arquivo |
| PDF do relatório | documentos do app | [app_report_exporter.dart](../../lib/features/reports/data/exporters/app_report_exporter.dart) |

## Camadas

1. **Genérica:** [HiveCollectionDataSource<M>](../../lib/core/storage/hive_collection_data_source.dart)
   faz o CRUD de uma box em que cada registro é um `Map` sob a chave do próprio id
   (`getAll`, `getById`, `put`, `putAll`, `delete`, `clear`). Cada feature estende informando
   o nome da box e a conversão Map ↔ Model.
2. **Por feature:** `data/datasources/local/<nome>_hive_data_source.dart` (estende a genérica),
   `data/models` (`toMap`/`fromMap`), `data/mappers` (Model ↔ Entity) e
   `data/repositories/local_<nome>_repository.dart`, que implementa a interface do domínio e
   traduz exceções em `Failure(CacheFailure())`.

Algumas classes ainda usam `Hive.box(...)` direto, para dados que não são coleção de
entidades: `AppMetaStore`, `FakeAuthRepository`, `LocalSubscriptionRepository`,
`LocalCouponRepository`, `BackupSettingsStore`.

## Campos comuns e exclusão

As entidades persistidas estendem `SyncableFields` (`id`, `createdAt`, `updatedAt`,
`deletedAt`, `syncStatus`, `version`), já prontas para uma sincronização futura. Excluir pelos
repositórios é **lógico** (`deletedAt`); os repositórios filtram os excluídos. O backup
inclui os excluídos; "Limpar dados" apaga de fato.

<a id="seed-e-migração"></a>

## Seed e migração

| Etapa | Quando roda | Controle |
|---|---|---|
| [SeedDefaults](../../lib/app/bootstrap/seed_defaults.dart) | uma vez, na 1ª execução | `defaultsSeeded` |
| [MigrationRunner](../../lib/app/bootstrap/migration_runner.dart) | enquanto `schemaVersion < currentSchemaVersion` (hoje `2`) | `schemaVersion` |

A migração converte o formato legado (box `box_buy_control`: uma lista de "boxes" com
"produtos" que na prática eram lançamentos) em `BoxEntity` + `TransactionEntity`. É
idempotente: reaproveita os ids das boxes legadas.

Ao mudar o formato de um Model: mantenha compatibilidade no `fromMap` (ex.: produtos antigos
com um único `barcode` continuam lidos) ou suba `currentSchemaVersion` e acrescente a etapa no
`MigrationRunner`. Se a mudança afetar o JSON do backup, avalie subir `backupFormatVersion`
e tratar o formato antigo no `ImportBackup`. Atualize esta página.
