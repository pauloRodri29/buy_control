# Textos

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [app_text](#app-text)

<a id="app-text"></a>

## app_text

**Código:** [lib/app/widgets/app_text.dart](../../../lib/app/widgets/app_text.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### AppText

Texto do app sobre a escala nativa do [TextTheme]:
- `AppText(...)` → `bodyLarge` (texto padrão)
- `AppText.title(...)` → `headlineSmall` (título de destaque, ex.: total)
- `AppText.heading(...)` → `titleLarge` (título de seção, sheet, diálogo)
- `AppText.small(...)` → `bodySmall` na cor principal
- `AppText.subtitle(...)` → `bodySmall` (tom secundário)
- `AppText.caption(...)` → `labelSmall` (legendas miúdas)

`fontSize`, `fontWeight` e `color` são ajustes pontuais sobre o estilo
do tema; sem eles, vale o que o tema define.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const AppText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

const AppText.title(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

const AppText.subtitle(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

const AppText.heading(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

const AppText.small(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

const AppText.caption(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

// Tipos dos campos públicos declarados nesta classe.
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final int? maxLines;
  final TextAlign textAlign;
  final TextOverflow? overflow;
```

</details>

**Onde usar como referência:**

- [lib/features/auth/presentation/pages/login_page.dart](../../../lib/features/auth/presentation/pages/login_page.dart)
- [lib/features/auth/presentation/pages/profile_page.dart](../../../lib/features/auth/presentation/pages/profile_page.dart)
- [lib/features/backup/presentation/pages/backup_history_page.dart](../../../lib/features/backup/presentation/pages/backup_history_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
AppText.subtitle(
                  'auth.signContinue'.tr,
                  textAlign: TextAlign.center,
                )
```

<details>
<summary>Opções declaradas neste arquivo</summary>

```dart
enum _AppTextKind { body, title, heading, small, subtitle, caption }
```

</details>

