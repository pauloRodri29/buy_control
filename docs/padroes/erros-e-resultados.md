# Erros, resultados, dinheiro e estados de tela

[Índice](../README.md) · [Nomenclatura](nomenclatura.md) · [Componentes](../componentes/README.md)

## `Result<T>`

Todo repositório e caso de uso que pode falhar devolve
[Result<T>](../../lib/core/result/result.dart) — `Success<T>(data)` ou `Failure<T>(failure)` — e
**nunca lança exceção** para quem chama. O repositório captura a exceção do Hive e devolve
`Failure(CacheFailure())`.

```dart
final result = await createBox(name: nome);
if (result case Failure(:final failure)) return FailurePresenter.show(failure);
final box = result.dataOrNull!;
```

Também disponíveis: `isSuccess`, `isFailure`, `dataOrNull`, `failureOrNull` e
`fold(onSuccess, onFailure)`.

## `AppFailure`

Hierarquia `sealed` em [app_failure.dart](../../lib/core/errors/app_failure.dart). A mensagem
padrão de cada falha é uma **chave de tradução**.

| Falha | Quando | Como aparece (`FailurePresenter.show`) |
|---|---|---|
| `ValidationFailure` | regra de negócio ou campo inválido | erro, título "Confira os dados" |
| `CacheFailure` | erro ao ler/gravar no Hive | erro, "Não foi possível concluir" |
| `NotFoundFailure` | registro inexistente | idem |
| `UnknownFailure` | inesperado | idem |
| `NetworkFailure` | rede/GitHub; mensagem já diz o que fazer | erro, "Falha de conexão" |
| `NotImplementedFailure` | recurso ainda não feito | informação, "Em breve" |
| `PlanLimitFailure` | limite ou módulo fora do plano | abre `PlanLimitPrompt` com atalho para os planos |
| `PurchaseDeclinedFailure` | pagamento recusado | erro |
| `PurchaseCancelledFailure` | usuário desistiu | nada |

Falha nova: acrescente a classe e o `case` no `switch` de
[FailurePresenter](../../lib/app/errors/failure_presenter.dart) (o `sealed` faz o compilador cobrar).

## Mostrar ao usuário

- **Estado de tela ou formulário:** `FailurePresenter.present(failure)` devolve só o texto
  (traduzido) para um `ErrorStateView` ou um campo.
- **Ações** (excluir, arquivar, exportar...): `FailurePresenter.show(failure)` ou
  `showIfFailure(result)` (devolve `true` em sucesso).
- **Avisos diretos:** `AppFeedback.info/success/error`, que funciona também de controllers
  (usa o `ScaffoldMessenger` raiz, `appScaffoldMessengerKey`).

<a id="erros-não-tratados"></a>

## Erros não tratados

`AppErrorHandler.install()` ([app_error_handler.dart](../../lib/app/errors/app_error_handler.dart)),
chamado no início do `main()`:

- `FlutterError.onError`: erros de build e layout;
- `PlatformDispatcher.instance.onError`: erros assíncronos não tratados — registrados no log e
  com um aviso genérico ao usuário;
- `ErrorWidget.builder`: só em release, troca a área cinza por um aviso nas cores do tema.

<a id="money"></a>

## `Money`

Todo valor monetário é [Money](../../lib/core/money/money.dart): centavos em `int`, nunca
`double` em cálculo. Operadores `+`, `-`, `*`, comparações, `Money.zero`, `formatted`
(`R$ 1.234,56`). Na tela, `AppMoneyField` + `MoneyInputFormatter` aplicam a máscara e
devolvem `Money`. `Money.fromReais(double)` só na fronteira (ex.: leitura legada).

## Estados de tela

| Enum | Valores | Uso |
|---|---|---|
| `ViewStatus` | `initial`, `loading`, `success`, `empty`, `error` | listas e telas de leitura |
| `FormStatus` | `idle`, `validating`, `submitting`, `success`, `failure` | formulários |

A tela faz `switch` no status e mostra `LoadingSkeleton`, `EmptyStateView`, `ErrorStateView`
ou o conteúdo. Regra de negócio fica no caso de uso; o controller só orquestra e guarda estado.
