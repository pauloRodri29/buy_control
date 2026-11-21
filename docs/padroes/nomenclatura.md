# Nomenclatura por tipo de classe

[Índice](../README.md) · [Navegação e estrutura](../configuracoes/navegacao.md) · [Erros e resultados](erros-e-resultados.md)

Regra de ouro: **1 tipo = 1 sufixo = 1 pasta**. Pelo nome da classe e pelo caminho do
arquivo dá para saber o que ela é. O arquivo é o `snake_case` da classe principal
(`BoxClosureEntity` → `box_closure_entity.dart`).

> `<Nome>` é marcador: troque pelo conceito (`Box`, `Product`, `PlanItem`...).
> Esta página descreve o padrão **em uso**; não há teste que o imponha, então revise no PR.

## Domínio (`domain/`) — Dart puro, sem Flutter, GetX ou Hive

| Tipo | Classe | Arquivo / pasta | Regras |
|---|---|---|---|
| Entidade persistida | `<Nome>Entity` | `domain/entities/<nome>_entity.dart` | estende `SyncableFields`; imutável, `copyWith` |
| Valor/regra de domínio | substantivo sem sufixo (`DiscountRule`, `Coupon`, `PlanDefinition`, `Entitlement`) | `domain/entities/` | sem persistência própria |
| Dado calculado | `<Nome>Progress`, `<Nome>Diff`, `<Nome>Snapshot` | `domain/entities/` | calculado em memória, não gravado |
| Contrato de repositório | `<Nome>Repository` (`abstract interface class`, **sem** prefixo `I`) | `domain/repositories/<nome>_repository.dart` | todo método devolve `Future<Result<T>>` |
| Caso de uso | verbo + objeto, **sem sufixo** (`CreateBox`, `CloseBox`, `GetConsolidatedReport`) | `domain/usecases/<verbo>_<objeto>.dart` | um método `call(...)`; regras de negócio e validação vivem aqui |
| Vários casos de uso pequenos do mesmo assunto | um arquivo `<assunto>_usecases.dart` | `domain/usecases/` | ex.: `plan_board_usecases.dart`, `subscription_usecases.dart` |
| Regra pura/estática | substantivo (`AccessPolicy`, `PlanItemPositions`, `ProductBarcodes`, `CustomPlanPricing`, `PlanCatalog`) | `domain/` ou `domain/usecases/` | só `static`, construtor privado |
| Resultado de caso de uso | `<Nome>Outcome` | ao lado do caso de uso | ex.: `CreateBoxOutcome` |

## Dados (`data/`)

| Tipo | Classe | Arquivo / pasta |
|---|---|---|
| Model (formato gravado) | `<Nome>Model` com `toMap`/`fromMap` | `data/models/<nome>_model.dart` |
| Mapper | `<Nome>Mapper` com `static toEntity`/`toModel` | `data/mappers/<nome>_mapper.dart` |
| Data source Hive | `<Nome>HiveDataSource` (estende `HiveCollectionDataSource<M>`) | `data/datasources/local/<nome>_hive_data_source.dart` |
| Repositório local | `Local<Nome>Repository implements <Nome>Repository` | `data/repositories/local_<nome>_repository.dart` |
| Implementação simulada | `Fake<Nome>` (`FakeAuthRepository`, `FakeBillingGateway`) | `data/repositories/` ou `data/billing/` |
| Remoto | `<Provedor><Nome>Remote` (`GithubBackupRemote`) | `data/` |

Model é o único lugar que conhece o formato gravado (Hive e JSON do backup). A entidade
não tem `toMap`.

## Apresentação (`presentation/`)

| Tipo | Padrão |
|---|---|
| Controller | `<Nome>Controller extends GetxController`, estado por campos + `update()` |
| Binding | `<Nome>Binding extends Bindings` em `presentation/bindings/` |
| Tela | `<Nome>Page` em `presentation/pages/` |
| Bottom sheet de fluxo | `<Nome>Sheet` (`ProductPickerSheet`, `ReportFiltersSheet`) |
| Formulário em sheet | `<Nome>FormSheet` em `presentation/widgets/` |
| Passo de um fluxo | `<Nome>Step` (`ItemDetailsStep`, `PurchaseSummaryStep`) |
| Orquestração de fluxo sem tela | função ou classe em `presentation/<nome>_flow.dart` (`add_items_flow.dart`) |
| Rascunho em memória | `<Nome>Draft` (`PurchaseDraft`) |
| Mixin de controller | substantivo (`PlanLocks`) |
| Componente compartilhado | `App<Nome>` em `lib/app/widgets/`; ver [Componentes](../componentes/README.md) |

## Infraestrutura (`app/` e `core/`)

| Tipo | Padrão | Exemplo |
|---|---|---|
| Token visual | `App<Token>` com `static const` | `AppSpacing`, `AppRadius`, `AppDurations` |
| Registro central | `<Nome>Registry` / `<Nome>Store` | `HiveBoxRegistry`, `AppMetaStore` |
| Falha | `<Motivo>Failure extends AppFailure` | `ValidationFailure`, `PlanLimitFailure` |
| Formatter | `<Nome>Formatter` / `<Nome>InputFormatter` | `DateTimeFormatter`, `MoneyInputFormatter` |
| Extension | `<Alvo>Extensions` em `<alvo>_extensions.dart` | `string_extensions.dart` |

## Chaves de tradução

`<feature>.<nomeEmCamelCase>` (`boxes.deleteBoxName`), `common.*` para textos de várias
features, `errors.*`, `catalog.*` e `format.*`. Ver [idioma](../configuracoes/visual-e-idioma.md#idioma).
