# Arquitetura

## Visão geral

Buy Control é um app Flutter offline-first, construído em Clean Architecture com três camadas por feature (`domain` → `data` → `presentation`), GetX como camada de apresentação/DI e Hive como persistência local. A arquitetura foi desenhada para que a troca de Hive por uma API remota no futuro não exija tocar em nenhuma tela — apenas em implementações de repositório.

```
UI (GetX Controller/Page) → UseCase → Repository (interface) → DataSource (Hive hoje / API amanhã)
```

## Estrutura de pastas

```
lib/
  app/                     # infraestrutura da aplicação, não é "regra de negócio"
    bindings/              # InitialBinding: DI global (repositórios + usecases de leitura)
    bootstrap/             # AppBootstrap, MigrationRunner, SeedDefaults
    navigation/            # AuthGate, MainShell (bottom navigation)
    routes/                # GetPages
    state/                 # ViewStatus, FormStatus (enums de estado de tela)
    theme/                 # design tokens (AppColors, AppSpacing, AppTypography...)
    widgets/                # design system reutilizável (AppButton, AppTextField, AppMoneyField...)
  core/                    # utilitários sem nenhuma dependência de feature
    database/              # HiveBoxRegistry, AppMetaStore, LegacyDataReader
    errors/                # AppFailure (sealed hierarchy)
    result/                # Result/Success/Failure
    money/                 # Money (value object em centavos) + MoneyInputFormatter
    sync/                  # SyncableFields, SyncStatus (preparo para sync futuro)
    formatters/, validators/, utils/, extensions/, storage/
  features/
    <feature>/
      domain/              # entities, repository (interface), usecases — zero Flutter/GetX/Hive
      data/                # models (toMap/fromMap), mappers, datasources (Hive), repository impl
      presentation/        # controllers (GetX), pages, widgets, bindings
```

Cada feature é uma vertical fechada. Features não importam a camada `data`/`presentation` umas das outras — quando uma feature precisa de outra (ex.: Relatórios precisa de Transações), ela depende apenas da interface de `domain/repositories` da outra, injetada via GetX.

## Camadas

### Domain
- **Entities**: classes Dart puras. A maioria estende `SyncableFields` (`id`, `createdAt`, `updatedAt`, `deletedAt`, `syncStatus`, `version`) — todo registro persistido já nasce pronto para sincronização multi-dispositivo futura.
- **Repository (interface)**: contrato abstrato (`abstract class XRepository`). Retorna sempre `Result<T>` (nunca lança exceção para o chamador).
- **UseCases**: uma classe por operação (`CreateBox`, `CloseBox`, `GetConsolidatedReport`...), com um único método `call(...)`. Validações de regra de negócio (nome obrigatório, e-mail válido, Box com lançamentos, etc.) vivem aqui, nunca na tela.

### Data
- **Models**: espelham a entidade + campos de sincronização, com `toMap()`/`fromMap()` para serialização no Hive.
- **Mappers**: `toEntity()`/`toModel()`, isolando o domain de qualquer detalhe de serialização.
- **DataSources**: `HiveCollectionDataSource<M>` é a base genérica (CRUD + `clear()`) reaproveitada por toda feature baseada em coleção; `HiveBoxRegistry` centraliza os nomes de todas as Hive boxes do app.
- **Repository (impl)**: implementa a interface do domain, traduzindo exceções em `Failure(CacheFailure(...))`.

### Presentation
- **Controllers**: `GetxController` com campos simples + `update()` (padrão *GetBuilder*, não `Rx`/`Obx`, por convenção deste projeto). Expõem um `ViewStatus` (`initial/loading/success/empty/error`) para a tela decidir o que renderizar.
- **Pages/Widgets**: consomem só usecases (nunca repositórios diretamente) e só sabem de `Money`, `ViewStatus` e das entidades — zero lógica de negócio.
- **Bindings**: cada feature registra (`lazyPut`) seu próprio controller + usecases de escrita. Repositórios e usecases de leitura mais compartilhados (usados por 2+ features) ficam em `InitialBinding`, registrados uma vez como singletons `permanent: true` — assim qualquer controller consegue `Get.find()` independentemente da ordem de navegação entre abas.

## `Result<T>` e tratamento de erro

Todo repositório e usecase que pode falhar retorna `Result<T>` (sealed: `Success<T>` ou `Failure<T>`), nunca lança exceção para quem chama. `AppFailure` é uma hierarquia sealed (`CacheFailure`, `ValidationFailure`, `NotFoundFailure`, `UnknownFailure`, `NotImplementedFailure`), permitindo que a UI trate cada caso (ex.: mostrar a mensagem de `ValidationFailure` num campo de formulário) sem `try/catch` espalhado.

## Money

Todo valor monetário passa por `Money` (`lib/core/money/money.dart`), que guarda centavos como `int` — nunca `double` bruto em cálculo financeiro, evitando erros de arredondamento. `MoneyInputFormatter` + o widget `AppMoneyField` aplicam máscara de moeda em tempo real em todo formulário do app, eliminando a duplicação de parsing manual que existia antes.

## Fechamentos (imutabilidade sem duplicação de dados)

Uma Box é um contexto de gasto que nunca "fecha" de verdade — ela continua recebendo lançamentos para sempre. Quando o usuário termina um ciclo de compras, ele pode "Fechar a Box": isso cria um `BoxClosureEntity` (um cabeçalho leve: data, total, contadores) e marca `closureId` em cada `TransactionEntity` aberto daquele momento.

A partir daí, um guard no domínio (`UpdateTransaction`/`DeleteTransaction`) rejeita qualquer tentativa de editar/excluir um lançamento com `closureId != null`. Isso significa que o "detalhe" de um Fechamento nunca precisa duplicar os lançamentos — ele é sempre obtido consultando `TransactionRepository` pelos registros com aquele `closureId`, que a essa altura são garantidamente imutáveis. Fechamentos são definitivos: não existe reabertura.

O usuário escolhe a data de referência do Fechamento (`referenceDate`), que também é copiada para cada lançamento (`closureReferenceDate`) para que balanço e relatórios agrupem pelo período fechado sem consultar os Fechamentos. Ao fechar, `CloseBox` copia os lançamentos para um novo ciclo aberto (ids novos), e reverte tudo se alguma gravação falhar.

Esse mesmo `closureId` é o que garante a regra "relatórios nunca refletem o estado atual da Box": `GetConsolidatedReport` filtra exclusivamente `transaction.isClosed`, então editar um lançamento aberto jamais altera um relatório já gerado.

## Autenticação

`AuthRepository` é uma interface de domínio; hoje só existe `FakeAuthRepository` (sessão persistida em uma Hive box dedicada, sem validação real de senha). O restante do app — `AuthController`, `LoginPage`, `ProfilePage`, `AuthGate` — depende apenas da interface. Trocar para uma API real no futuro é implementar `ApiAuthRepository implements AuthRepository` e registrar essa classe em `InitialBinding` — nenhuma tela muda.

## Backup/Import (JSON) vs. Exportação de Relatório (PDF)

São dois recursos intencionalmente separados:
- `lib/features/backup/`: dump/restauração de **todos** os dados do app (Boxes, Produtos, Categorias, Tipos, Unidades, Transações, Fechamentos) em um único JSON, usado para backup manual e migração de aparelho.
- `lib/features/reports/data/exporters/`: gera um **PDF de um relatório filtrado** (não é um backup de dados). Implementa a interface `ReportExporter`, hoje via `AppReportExporter` (pacote `pdf`+`printing`); CSV e JSON-a-partir-do-relatório ficam com stub (`NotImplementedFailure`), prontos para implementação futura sem mudar o contrato.

## Migração e bootstrap

`AppBootstrap.run()` (chamado uma vez em `main()`) abre o Hive (`HiveBoxRegistry.initHive()`), roda `SeedDefaults` (categorias/tipos/unidades padrão, uma única vez, controlado por uma flag em `AppMetaStore`) e `MigrationRunner` (migra dados de um formato legado anterior à Clean Architecture, também idempotente).

## Navegação

`AuthGate` (widget raiz, registrado como `initialRoute`) decide entre `LoginPage` e `MainShell` de acordo com `AuthController.status`. `MainShell` é uma Bottom Navigation com `IndexedStack` (preserva estado/scroll de cada aba); os bindings de cada aba são inicializados uma única vez ao montar o shell.

## Testes

Testes de unidade cobrem usecases de domínio (`test/features/<feature>/...`), usando repositórios fake em memória (nunca Hive real), validando regras de negócio e os guards de imutabilidade dos Fechamentos.
