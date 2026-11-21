# Visual e idioma

[Configurações](README.md) · [Componentes](../componentes/README.md)

## Tema

O app usa só o tema nativo do **Material 3**, montado em [AppTheme](../../lib/app/theme/app_theme.dart):
`ColorScheme` explícito para claro e escuro, `TextTheme` como escala tipográfica e o tema de
cada componente (botões, cards, campos, chips, sheets, diálogos, snackbars...).

- Telas e widgets **não** definem cores fixas nem checam `brightness`: leem do tema por
  `context.colors`, `context.text` e `context.semantic` ([theme_context.dart](../../lib/app/theme/theme_context.dart)).
- Cores que o `ColorScheme` não cobre (sucesso, aviso e a paleta dos gráficos) ficam em
  [AppSemanticColors](../../lib/app/theme/app_semantic_colors.dart), uma `ThemeExtension`.
  As séries dos gráficos seguem uma ordem validada para daltonismo; `Outros` tem cor própria.
- Para mudar um componente em todo o app, ajuste o tema dele no `AppTheme`, não a tela.
- `ThemeController` guarda a escolha (automático, claro, escuro) no `app_meta`.

## Tokens

| Token | Valores | Fonte |
|---|---|---|
| `AppSpacing` | `xs` 4 · `sm` 8 · `md` 12 · `lg` 16 · `xl` 24 · `xxl` 32 | [app_spacing.dart](../../lib/app/theme/app_spacing.dart) |
| `AppRadius` | `sm` 8 · `md` 10 · `lg` 12 · `xl` 20 · `full` | [app_radius.dart](../../lib/app/theme/app_radius.dart) |
| `AppDurations` | `fast` 120 ms · `normal` 200 ms · `slow` 600 ms · `searchDebounce` 300 ms | [app_durations.dart](../../lib/app/theme/app_durations.dart) |
| `AppIconStyle` | peso 200, contorno, tamanho óptico 24 | [app_icon_style.dart](../../lib/app/theme/app_icon_style.dart) |

## Ícones

Fonte variável **Material Symbols** (`Symbols.*`, pacote `material_symbols_icons`), não a
`Icons.*`. Peso, preenchimento e grade vêm do `iconTheme`; para trocar o traço de todos os
ícones, altere `AppIconStyle.weight`. Ícone marcado: `Icon(Symbols.check_circle, fill: 1)`.

## Marca

[AppBrand](../../lib/app/brand/app_brand.dart) centraliza nome (**GastoLog**), frase
("Cada gasto, registrado."), fontes e cores:

- verde-petróleo `#0F766E` (principal; `#14B8A6` no escuro) e âmbar `#F59E0B` (destaque);
- **Plus Jakarta Sans** no app e **JetBrains Mono** na splash e no símbolo, embutidas
  (licença OFL, registradas em [font_licenses.dart](../../lib/app/brand/font_licenses.dart));
- símbolo desenhado em código (`AppLogoPainter`, em [app_logo.dart](../../lib/app/brand/app_logo.dart)),
  o mesmo usado para gerar ícone e splash ([ferramentas](../../tool/README.md#marca-ícone-e-splash)).

## Idioma

Português (Brasil) e inglês, com as traduções do GetX:

- **Chaves semânticas:** o código não tem texto visível; usa `'common.save'.tr` ou, com
  valores, `.trParams({...})`. Formato `<feature>.<nome>`; textos de várias features em
  `common.*`, erros em `errors.*`, catálogos padrão em `catalog.*`, padrões de data em `format.*`.
- **Um JSON por idioma** em [assets/i18n](../../assets/i18n/), com as mesmas chaves e os
  mesmos `@parâmetros`. Chave que faltar num idioma aparece em português.
- **Enums e listas `const`** guardam a chave crua e traduzem na leitura (getter com `.tr`,
  ex.: `ResourceKey.label`), para acompanhar a troca de idioma sem reiniciar.
- **Falhas:** as mensagens padrão de `AppFailure` são chaves; `FailurePresenter.present` traduz.
- `LocaleController` guarda a escolha no `app_meta` e aplica com `Get.updateLocale`.

### Acrescentar um texto

1. Chave nova em `pt_BR.json` **e** em `en_US.json`, com os mesmos parâmetros.
2. Use `'feature.chave'.tr` no código.
3. Rode `flutter test test/core/i18n/translations_test.dart`: ele falha se uma chave usada em
   `lib/` faltar, se os JSON tiverem chaves diferentes ou se os parâmetros divergirem.

### Acrescentar um idioma

Crie `assets/i18n/<código>.json` com as mesmas chaves e registre um `AppLanguage` em
`AppLocale.languages` ([app_locale.dart](../../lib/core/i18n/app_locale.dart)). Seletor,
`GetMaterialApp`, datas e reconhecimento dos catálogos padrão passam a incluí-lo.

## Datas e dinheiro

- Datas usam `AppLocale.intl` (`pt_BR`/`en_US`) e padrões traduzidos
  ([date_time_formatter.dart](../../lib/core/formatters/date_time_formatter.dart)).
- Dinheiro é sempre `Money` (centavos em `int`) e continua no formato do Real (`R$ 1.234,56`)
  em qualquer idioma. Ver [Erros e resultados](../padroes/erros-e-resultados.md#money).
