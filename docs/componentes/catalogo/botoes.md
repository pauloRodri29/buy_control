# Botões

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [app_button](#app-button)

<a id="app-button"></a>

## app_button

**Código:** [lib/app/widgets/app_button.dart](../../../lib/app/widgets/app_button.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppButton

Botão do app sobre os botões nativos do Material:
- primary → [FilledButton] (estilo do `filledButtonTheme`)
- secondary → [FilledButton] tonal (superfície neutra)
- danger → [FilledButton] na cor de erro
- text → [TextButton]

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.height = 48,
    this.expanded = true,
  });

const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = true,
  });

const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = true,
  });

const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 40,
    this.expanded = false,
  });

// Tipos dos campos públicos declarados nesta classe.
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final double height;
  final bool expanded;
```

</details>

**Onde usar como referência:**

- [lib/app/widgets/app_date_picker.dart](../../../lib/app/widgets/app_date_picker.dart)
- [lib/app/widgets/barcode_scanner_page.dart](../../../lib/app/widgets/barcode_scanner_page.dart)
- [lib/app/widgets/empty_state_view.dart](../../../lib/app/widgets/empty_state_view.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppButton.secondary(label: 'common.cancel'.tr, onPressed: () => Navigator.of(context).pop())
```

<details>
<summary>Opções declaradas neste arquivo</summary>

```dart
enum AppButtonVariant { primary, secondary, danger, text }
```

</details>

