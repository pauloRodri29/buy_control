# Avisos, vazio, erro e carregamento

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [app_feedback](#app-feedback)
- [empty_state_view](#empty-state-view)
- [error_state_view](#error-state-view)
- [loading_skeleton](#loading-skeleton)

<a id="app-feedback"></a>

## app_feedback

**Código:** [lib/app/widgets/app_feedback.dart](../../../lib/app/widgets/app_feedback.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppFeedback

Avisos rápidos ao usuário com o [SnackBar] nativo (estilo vindo do
`snackBarTheme`). Substitui o `Get.snackbar`.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
static void info(String message, {String? title});

static void success(String message, {String? title});

static void error(String message, {String? title});

```

</details>

**Onde usar como referência:**

- [lib/app/errors/app_error_handler.dart](../../../lib/app/errors/app_error_handler.dart)
- [lib/app/errors/failure_presenter.dart](../../../lib/app/errors/failure_presenter.dart)
- [lib/app/widgets/barcode_scanner_page.dart](../../../lib/app/widgets/barcode_scanner_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppFeedback.error(_genericMessage, title: 'errors.unexpectedError'.tr)
```

<details>
<summary>Opções declaradas neste arquivo</summary>

```dart
enum _FeedbackKind { info, success, error }
```

</details>

<a id="empty-state-view"></a>

## empty_state_view

**Código:** [lib/app/widgets/empty_state_view.dart](../../../lib/app/widgets/empty_state_view.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### EmptyStateView

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const EmptyStateView({
    super.key,
    this.icon = Symbols.inbox,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

// Tipos dos campos públicos declarados nesta classe.
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/boxes/presentation/pages/box_detail_page.dart](../../../lib/features/boxes/presentation/pages/box_detail_page.dart)
- [lib/features/box_closures/presentation/pages/box_closures_page.dart](../../../lib/features/box_closures/presentation/pages/box_closures_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
EmptyStateView(
          icon: Symbols.inventory_2,
          title: 'boxes.noBoxesRegistered'.tr,
          message: 'boxes.createBoxesOrganizePurchasesLike'.tr,
          actionLabel: 'boxes.newBox'.tr,
          onAction: () => _openForm(context),
        )
```

<a id="error-state-view"></a>

## error_state_view

**Código:** [lib/app/widgets/error_state_view.dart](../../../lib/app/widgets/error_state_view.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### ErrorStateView

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const ErrorStateView({super.key, required this.message, this.onRetry});

// Tipos dos campos públicos declarados nesta classe.
  final String message;
  final VoidCallback? onRetry;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/boxes/presentation/pages/box_detail_page.dart](../../../lib/features/boxes/presentation/pages/box_detail_page.dart)
- [lib/features/box_closures/presentation/pages/box_closures_page.dart](../../../lib/features/box_closures/presentation/pages/box_closures_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
ErrorStateView(message: controller.errorMessage ?? 'common.unexpectedError'.tr, onRetry: controller.load)
```

<a id="loading-skeleton"></a>

## loading_skeleton

**Código:** [lib/app/widgets/loading_skeleton.dart](../../../lib/app/widgets/loading_skeleton.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### LoadingSkeleton

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const LoadingSkeleton({super.key, this.height = 16, this.width, this.borderRadius});

// Tipos dos campos públicos declarados nesta classe.
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
```

</details>

**Onde usar como referência:**

- [lib/features/dashboard/presentation/pages/dashboard_page.dart](../../../lib/features/dashboard/presentation/pages/dashboard_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
LoadingSkeleton(height: 236, borderRadius: AppRadius.borderLg)
```

### LoadingSkeletonList

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const LoadingSkeletonList({super.key, this.itemCount = 6, this.itemHeight = 72});

// Tipos dos campos públicos declarados nesta classe.
  final int itemCount;
  final double itemHeight;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/boxes/presentation/pages/box_detail_page.dart](../../../lib/features/boxes/presentation/pages/box_detail_page.dart)
- [lib/features/box_closures/presentation/pages/box_closures_page.dart](../../../lib/features/box_closures/presentation/pages/box_closures_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
LoadingSkeletonList()
```

