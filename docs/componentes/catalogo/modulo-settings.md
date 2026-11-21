# Módulo: Configurações

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [language_sheet](#language-sheet)
- [theme_mode_sheet](#theme-mode-sheet)

<a id="language-sheet"></a>

## language_sheet

**Código:** [lib/features/settings/presentation/widgets/language_sheet.dart](../../../lib/features/settings/presentation/widgets/language_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### LanguageSheet

Escolha do idioma (português ou inglês). A troca é aplicada na hora,
sem botão de confirmar. Cada idioma aparece com o nome nele mesmo.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const LanguageSheet({super.key});

```

</details>

**Onde usar como referência:**

- [lib/features/settings/presentation/pages/settings_page.dart](../../../lib/features/settings/presentation/pages/settings_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
LanguageSheet()
```

<a id="theme-mode-sheet"></a>

## theme_mode_sheet

**Código:** [lib/features/settings/presentation/widgets/theme_mode_sheet.dart](../../../lib/features/settings/presentation/widgets/theme_mode_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### ThemeModeSheet

Escolha do tema (sistema/claro/escuro). A troca é aplicada na hora,
sem botão de confirmar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const ThemeModeSheet({super.key});

```

</details>

**Onde usar como referência:**

- [lib/features/settings/presentation/pages/settings_page.dart](../../../lib/features/settings/presentation/pages/settings_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
ThemeModeSheet()
```

