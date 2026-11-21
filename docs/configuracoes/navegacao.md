# Navegação, estrutura e injeção de dependências

[Configurações](README.md) · [Nomenclatura](../padroes/nomenclatura.md) · [Armazenamento](armazenamento.md)

## Inicialização

`main()` ([main.dart](../../lib/main.dart)), nesta ordem:

1. `AppErrorHandler.install()` — ganchos globais de erro ([Erros e resultados](../padroes/erros-e-resultados.md#erros-não-tratados)).
2. Licenças das fontes embutidas (`registerFontLicenses`).
3. Formatação de datas para cada idioma e leitura das traduções (`AppLocale.loadTranslations`);
   o idioma do aparelho já vale aqui, porque o seed cria os catálogos nesse idioma.
4. `AppBootstrap.run()`: abre todas as Hive boxes, roda `SeedDefaults` e `MigrationRunner`
   ([Armazenamento](armazenamento.md#seed-e-migração)).
5. `ThemeController` e `LocaleController` registrados antes do `runApp` (o primeiro frame já
   precisa de tema e idioma).
6. `GetMaterialApp` com `initialBinding: InitialBinding()` e `initialRoute: '/splash'`.

## Rotas e telas

Só existem duas rotas nomeadas ([routes.dart](../../lib/app/routes/routes.dart)):

| Rota | Tela |
|---|---|
| `/splash` | `SplashPage` (animação de abertura) |
| `/` | `AuthGate` → `LoginPage` ou `MainShell` |

O `MainShell` tem cinco abas num `IndexedStack` (estado e rolagem preservados):
**Início**, **Boxes**, **Produtos**, **Planejar**, **Mais**. Os bindings das quatro primeiras
são registrados uma vez, ao montar o shell, e tocar numa aba recarrega o controller dela
(`load()`), para refletir mudanças feitas em outra tela.

Todas as demais telas abrem com `Get.to(() => Tela(), binding: XBinding())`, a partir das
abas ou do menu **Mais** (Relatórios, Categorias, Tipos de Produto, Unidades,
Configurações; "Sincronização" como "Em breve").

Para acrescentar uma aba: página + binding na feature, item no `BottomNavigationBar` e
recarga no `onTap` do [main_shell.dart](../../lib/app/navigation/main_shell.dart). Para um
item do menu Mais: `ListTile` em [more_page.dart](../../lib/features/more/presentation/pages/more_page.dart).

## Estrutura de pastas

```
lib/
  main.dart
  app/            infraestrutura da aplicação (não é regra de negócio)
    bindings/     InitialBinding: DI global
    bootstrap/    AppBootstrap, SeedDefaults, MigrationRunner
    brand/        AppBrand, AppLogo, licenças das fontes
    errors/       AppErrorHandler, FailurePresenter
    i18n/         AppTranslations, LocaleController
    navigation/   SplashPage, AuthGate, MainShell
    routes/       Pages, Routes
    state/        ViewStatus, FormStatus
    theme/        AppTheme, AppSemanticColors, tokens, ThemeController
    widgets/      componentes compartilhados
  core/           utilitários sem dependência de feature
    barcode/ catalog/ database/ errors/ extensions/ formatters/
    i18n/ money/ result/ storage/ sync/ utils/ validators/
  features/<feature>/
    domain/       entities, repositories (interface), usecases — sem Flutter/GetX/Hive
    data/         models, mappers, datasources/local (Hive), repositories (impl)
    presentation/ bindings, controllers, pages, widgets
```

Cada feature é uma vertical fechada. Uma feature não importa `data`/`presentation` de
outra: quando precisa dela (ex.: Relatórios lê Transações), depende só da interface em
`domain/repositories` da outra, injetada pelo GetX. Exceções conhecidas: `backup` e
`settings` usam data sources de outras features diretamente (são dump/limpeza de
armazenamento, não regra de negócio).

```
Page/Widget → Controller (GetX) → UseCase → Repository (interface) → DataSource (Hive)
```

## Injeção de dependências

| Onde | O que registra | Como |
|---|---|---|
| [InitialBinding](../../lib/app/bindings/initial_binding.dart) | todos os repositórios; casos de uso de leitura usados por 2+ features; auth; assinatura (`SubscriptionController`, `QuotaGuard`, `BillingGateway`...) | `Get.put(..., permanent: true)` |
| `<feature>/presentation/bindings/*_binding.dart` | controller da tela e casos de uso de escrita | `Get.lazyPut` |
| `main.dart` | `ThemeController`, `LocaleController` | `Get.put(..., permanent: true)` |

Assim qualquer controller faz `Get.find()` sem depender da ordem de navegação entre abas.
Para trocar uma implementação (ex.: `FakeAuthRepository` → API real, `FakeBillingGateway` →
loja), troque só o registro no `InitialBinding`.

## Estado de tela

Controllers são `GetxController` com campos simples e `update()` (padrão `GetBuilder`, não
`Rx`/`Obx`). Expõem `ViewStatus` (`initial`, `loading`, `success`, `empty`, `error`) para a tela
decidir o que mostrar; formulários usam `FormStatus`. O GetX fica com DI, estado e navegação;
`SnackBar`, diálogos, bottom sheets e tema são nativos do Flutter.
