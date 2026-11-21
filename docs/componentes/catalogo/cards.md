# Cards e itens de lista

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [app_card](#app-card)
- [app_list_card](#app-list-card)

<a id="app-card"></a>

## app_card

**Código:** [lib/app/widgets/app_card.dart](../../../lib/app/widgets/app_card.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppCard

[Card] nativo (cor, borda e raio vêm do `cardTheme`) com toque opcional
e um leve "afundar" ao pressionar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
    this.onLongPress,
  });

// Tipos dos campos públicos declarados nesta classe.
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
```

</details>

**Onde usar como referência:**

- [lib/app/widgets/app_list_card.dart](../../../lib/app/widgets/app_list_card.dart)
- [lib/features/auth/presentation/pages/profile_page.dart](../../../lib/features/auth/presentation/pages/profile_page.dart)
- [lib/features/backup/presentation/pages/backup_page.dart](../../../lib/features/backup/presentation/pages/backup_page.dart)

<a id="app-list-card"></a>

## app_list_card

**Código:** [lib/app/widgets/app_list_card.dart](../../../lib/app/widgets/app_list_card.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppListCardAction

Ação do menu ⋮ de um [AppListCard].

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppListCardAction(this.label, this.onSelected, {this.destructive = false});

// Tipos dos campos públicos declarados nesta classe.
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/categories/presentation/pages/categories_page.dart](../../../lib/features/categories/presentation/pages/categories_page.dart)
- [lib/features/products/presentation/pages/products_page.dart](../../../lib/features/products/presentation/pages/products_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppListCardAction('common.edit'.tr, onEdit)
```

### AppListCard

Item padrão das listas do app (Boxes, Produtos, catálogos...):

```
┌────────────────────────────────────┐
│ Título                           ⋮ │
│ linha secundária (opcional)        │
│ R$ 12,00  ← destaque (opcional)    │
│ detalhe • detalhe                  │
└────────────────────────────────────┘
```

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.highlight,
    this.details = const [],
    this.leading,
    this.onTap,
    this.actions = const [],
    this.locked = false,
  });

// Tipos dos campos públicos declarados nesta classe.
  final String title;
  final String? subtitle;
  final String? highlight;
  final List<String> details;
  final Widget? leading;
  final VoidCallback? onTap;
  final List<AppListCardAction> actions;
  final bool locked;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)
- [lib/features/categories/presentation/pages/categories_page.dart](../../../lib/features/categories/presentation/pages/categories_page.dart)
- [lib/features/products/presentation/pages/products_page.dart](../../../lib/features/products/presentation/pages/products_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppListCard(
      title: box.name,
      highlight: total,
      details: [
        'boxes.entriesTransactionCount'.trParams({'transactionCount': '$transactionCount'}),
        lastMovement == null
            ? 'boxes.noActivity'.tr
            : 'boxes.lastActivityRelative'.trParams({'relative': DateTimeFormatter.relative(lastMovement)}),
      ],
      onTap: onTap,
      locked: locked,
      actions: [
        AppListCardAction('common.edit'.tr, onEdit),
        AppListCardAction(box.isArchived ? 'common.unarchive'.tr : 'common.archive'.tr, onArchive),
        AppListCardAction('common.delete'.tr, onDelete, destructive: true),
      ],
    )
```

