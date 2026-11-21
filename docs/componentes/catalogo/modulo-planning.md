# Módulo: Planejamento

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [finish_plan_board_sheet](#finish-plan-board-sheet)
- [pending_items_view](#pending-items-view)
- [plan_board_form_sheet](#plan-board-form-sheet)
- [plan_board_picker](#plan-board-picker)
- [plan_column](#plan-column)
- [plan_history_view](#plan-history-view)
- [plan_item_card](#plan-item-card)
- [plan_item_form_sheet](#plan-item-form-sheet)

<a id="finish-plan-board-sheet"></a>

## finish_plan_board_sheet

**Código:** [lib/features/planning/presentation/widgets/finish_plan_board_sheet.dart](../../../lib/features/planning/presentation/widgets/finish_plan_board_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### FinishPlanBoardSheet

Finalização (ou cancelamento) de um quadro. É definitivo, então a tela
resolve tudo antes:
- cada item não comprado vai para outro quadro aberto ou para
  Pendências, com um motivo (sem outros quadros, só Pendências);
- itens comprados sem valor podem receber o valor pago.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const FinishPlanBoardSheet({super.key, required this.board, this.ending = PlanBoardEnding.finish});

// Tipos dos campos públicos declarados nesta classe.
  final PlanBoardEntity board;
  final PlanBoardEnding ending;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/planning_page.dart](../../../lib/features/planning/presentation/pages/planning_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
FinishPlanBoardSheet(board: board)
```

<a id="pending-items-view"></a>

## pending_items_view

**Código:** [lib/features/planning/presentation/widgets/pending_items_view.dart](../../../lib/features/planning/presentation/widgets/pending_items_view.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PendingItemsView

Aba Pendências: itens que não foram comprados quando o quadro foi
finalizado. Ficam aqui até irem para um quadro (deslizar para a
esquerda) ou serem excluídos (deslizar para a direita).

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PendingItemsView({super.key});

```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/planning_page.dart](../../../lib/features/planning/presentation/pages/planning_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PendingItemsView()
```

<details>
<summary>Opções declaradas neste arquivo</summary>

```dart
enum _PendingAction { send, delete }
```

</details>

<a id="plan-board-form-sheet"></a>

## plan_board_form_sheet

**Código:** [lib/features/planning/presentation/widgets/plan_board_form_sheet.dart](../../../lib/features/planning/presentation/widgets/plan_board_form_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanBoardFormSheet

Formulário de criação/edição de quadro. Estado local (rascunho) até
tocar em Salvar. Com [template], cria um quadro novo copiando os itens
de outro (ex.: um quadro do Histórico).

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanBoardFormSheet({super.key, this.board, this.template});

// Tipos dos campos públicos declarados nesta classe.
  final PlanBoardEntity? board;
  final PlanBoardEntity? template;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/planning_page.dart](../../../lib/features/planning/presentation/pages/planning_page.dart)
- [lib/features/planning/presentation/pages/plan_board_history_page.dart](../../../lib/features/planning/presentation/pages/plan_board_history_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanBoardFormSheet(board: board)
```

<a id="plan-board-picker"></a>

## plan_board_picker

**Código:** [lib/features/planning/presentation/widgets/plan_board_picker.dart](../../../lib/features/planning/presentation/widgets/plan_board_picker.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

Este arquivo não declara classe pública. Consulte a fonte para funções auxiliares.

### showPlanBoardPicker

Função pública: use os argumentos abaixo. O retorno e as opções são parte do contrato.

```dart
Future<PlanBoardEntity?> showPlanBoardPicker(
  BuildContext context, {
  required String title,
  required List<PlanBoardEntity> boards,
});
```

Exemplo de integração: [lib/features/planning/presentation/widgets/pending_items_view.dart](../../../lib/features/planning/presentation/widgets/pending_items_view.dart).

<a id="plan-column"></a>

## plan_column

**Código:** [lib/features/planning/presentation/widgets/plan_column.dart](../../../lib/features/planning/presentation/widgets/plan_column.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanColumn

Coluna do kanban: um quadro (ou "Sem quadro" quando [board] é `null`).
Aceita itens arrastados: soltar sobre um card insere antes dele; soltar
no espaço livre da coluna coloca no final.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanColumn({
    super.key,
    required this.board,
    required this.items,
    required this.progress,
    required this.width,
    required this.onAddItem,
    required this.onBoardAction,
    required this.onEditItem,
    required this.onTogglePurchased,
    required this.onItemAction,
    required this.onDropItem,
    this.onDragUpdate,
    this.onDragEnd,
    this.locked = false,
    this.lockedItemIds = const {},
    this.onLockedTap,
  });

// Tipos dos campos públicos declarados nesta classe.
  final PlanBoardEntity? board;
  final List<PlanItemEntity> items;
  final PlanBoardProgress progress;
  final double width;
  final VoidCallback onAddItem;
  final ValueChanged<PlanBoardAction> onBoardAction;
  final ValueChanged<PlanItemEntity> onEditItem;
  final ValueChanged<PlanItemEntity> onTogglePurchased;
  final void Function(PlanItemEntity item, PlanItemAction action) onItemAction;
  final void Function(PlanItemEntity item, String? beforeItemId) onDropItem;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final bool locked;
  final Set<String> lockedItemIds;
  final VoidCallback? onLockedTap;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/planning_page.dart](../../../lib/features/planning/presentation/pages/planning_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanColumn(
          key: ValueKey(board?.id ?? '__inbox__'),
          board: board,
          items: controller.itemsOf(board?.id),
          progress: controller.progressOf(board),
          width: width,
          onAddItem: () => _openItemForm(context, boardId: board?.id),
          onBoardAction: (action) => _onBoardAction(context, board!, action),
          onEditItem: (item) => _openItemForm(context, item: item),
          onTogglePurchased: (item) async => _showError(await controller.togglePurchasedOf(item)),
          onItemAction: (item, action) => _onItemAction(context, item, action),
          onDropItem: (item, beforeId) async =>
              _showError(await controller.move(item, toBoardId: board?.id, beforeItemId: beforeId)),
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
          locked: board != null && controller.isLocked(board.id),
          lockedItemIds: controller.lockedItemIds,
          onLockedTap: controller.showLockedPrompt,
        )
```

<details>
<summary>Opções declaradas neste arquivo</summary>

```dart
enum PlanBoardAction { edit, finish, cancel, archive, unarchive, delete }
```

</details>

<a id="plan-history-view"></a>

## plan_history_view

**Código:** [lib/features/planning/presentation/widgets/plan_history_view.dart](../../../lib/features/planning/presentation/widgets/plan_history_view.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanHistoryView

Aba Histórico: quadros finalizados e cancelados, do mais recente para
o mais antigo.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanHistoryView({super.key});

```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/planning_page.dart](../../../lib/features/planning/presentation/pages/planning_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanHistoryView()
```

### PlanBoardStatusChip

Selo "Finalizado"/"Cancelado" de um quadro do Histórico.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanBoardStatusChip({super.key, required this.board});

PlanBoardStatusChip(board: board);

// Tipos dos campos públicos declarados nesta classe.
  final PlanBoardEntity board;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/plan_board_history_page.dart](../../../lib/features/planning/presentation/pages/plan_board_history_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanBoardStatusChip(board: board)
```

### PlanHistoryCard

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanHistoryCard({super.key, required this.board, required this.progress, required this.onTap});

// Tipos dos campos públicos declarados nesta classe.
  final PlanBoardEntity board;
  final PlanBoardProgress progress;
  final VoidCallback onTap;
```

</details>

**Integração:** nenhuma chamada direta encontrada fora deste arquivo. Pode ser usado só por herança, `static` ou dentro do próprio arquivo; confira a fonte antes de adotar ou remover.

<a id="plan-item-card"></a>

## plan_item_card

**Código:** [lib/features/planning/presentation/widgets/plan_item_card.dart](../../../lib/features/planning/presentation/widgets/plan_item_card.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanItemCard

Card de um item no kanban: check de "comprado", título, descrição e
valor estimado.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanItemCard({super.key, required this.item, this.onTap, this.onTogglePurchased, this.onAction});

// Tipos dos campos públicos declarados nesta classe.
  final PlanItemEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePurchased;
  final ValueChanged<PlanItemAction>? onAction;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/widgets/plan_column.dart](../../../lib/features/planning/presentation/widgets/plan_column.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanItemCard(item: item, onTap: onLockedTap)
```

<details>
<summary>Opções declaradas neste arquivo</summary>

```dart
enum PlanItemAction { edit, move, delete }
```

</details>

<a id="plan-item-form-sheet"></a>

## plan_item_form_sheet

**Código:** [lib/features/planning/presentation/widgets/plan_item_form_sheet.dart](../../../lib/features/planning/presentation/widgets/plan_item_form_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanItemFormSheet

Formulário de criação/edição de item planejado.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanItemFormSheet({super.key, this.item, this.initialBoardId});

// Tipos dos campos públicos declarados nesta classe.
  final PlanItemEntity? item;
  final String? initialBoardId;
```

</details>

**Onde usar como referência:**

- [lib/features/planning/presentation/pages/planning_page.dart](../../../lib/features/planning/presentation/pages/planning_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanItemFormSheet(item: item, initialBoardId: boardId)
```

