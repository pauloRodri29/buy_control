# Bottom sheets e diálogos

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [app_bottom_sheet](#app-bottom-sheet)
- [confirm_dialog](#confirm-dialog)
- [text_input_dialog](#text-input-dialog)

<a id="app-bottom-sheet"></a>

## app_bottom_sheet

**Código:** [lib/app/widgets/app_bottom_sheet.dart](../../../lib/app/widgets/app_bottom_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppBottomSheet

Conteúdo padrão de bottom sheet: margens do app, rolagem quando o
teclado abre e área segura da barra de navegação do aparelho. Cor,
cantos e alça vêm do `bottomSheetTheme` nativo.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppBottomSheet({super.key, required this.child, this.height});

static Future<T?> show<T>(BuildContext context, {required Widget child, double? height});

// Tipos dos campos públicos declarados nesta classe.
  final Widget child;
  final double? height;
```

</details>

**Onde usar como referência:**

- [lib/app/widgets/app_date_picker.dart](../../../lib/app/widgets/app_date_picker.dart)
- [lib/features/auth/presentation/pages/profile_page.dart](../../../lib/features/auth/presentation/pages/profile_page.dart)
- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppBottomSheet.show<DateTime>(
      context,
      child: _AppDatePickerSheet(
        title: title,
        confirmLabel: confirmLabel,
        firstDate: _dateOnly(firstDate),
        lastDate: _dateOnly(lastDate),
        initialDate: _dateOnly(initialDate),
        shortcuts: shortcuts,
      ),
    )
```

<a id="confirm-dialog"></a>

## confirm_dialog

**Código:** [lib/app/widgets/confirm_dialog.dart](../../../lib/app/widgets/confirm_dialog.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### ConfirmDialog

Diálogo de confirmação padrão ([AlertDialog] nativo) para ações
destrutivas: título explícito com o nome do item e um corpo que explica
o impacto da ação, nunca apenas "Excluir?".

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'common.confirm',
    this.isDestructive = true,
  });

static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'common.delete',
    bool isDestructive = true,
  });

// Tipos dos campos públicos declarados nesta classe.
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;
```

</details>

**Onde usar como referência:**

- [lib/features/auth/presentation/pages/profile_page.dart](../../../lib/features/auth/presentation/pages/profile_page.dart)
- [lib/features/backup/presentation/pages/github_settings_page.dart](../../../lib/features/backup/presentation/pages/github_settings_page.dart)
- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
ConfirmDialog.show(
      context,
      title: 'common.signOutAccount'.tr,
      message: 'auth.youllNeedSignAgainEmail'.tr,
      confirmLabel: 'common.signOut'.tr,
    )
```

<a id="text-input-dialog"></a>

## text_input_dialog

**Código:** [lib/app/widgets/text_input_dialog.dart](../../../lib/app/widgets/text_input_dialog.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### TextInputDialog

Diálogo padrão ([AlertDialog] nativo) para pedir um único texto ao
usuário (ex.: nome de um item, código digitado). Devolve o texto sem
espaços nas pontas, ou `null` se o usuário cancelar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const TextInputDialog({
    super.key,
    required this.title,
    this.hint,
    this.confirmLabel = 'OK',
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

static Future<String?> show(
    BuildContext context, {
    required String title,
    String? hint,
    String confirmLabel = 'OK',
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  });

// Tipos dos campos públicos declarados nesta classe.
  final String title;
  final String? hint;
  final String confirmLabel;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
```

</details>

**Onde usar como referência:**

- [lib/app/widgets/barcode_scanner_page.dart](../../../lib/app/widgets/barcode_scanner_page.dart)
- [lib/features/transactions/presentation/scan_items_flow.dart](../../../lib/features/transactions/presentation/scan_items_flow.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
TextInputDialog.show(
      context,
      title: 'common.typeCode'.tr,
      hint: 'common.barcodeDigits'.tr,
      keyboardType: TextInputType.number,
    )
```

