# Componentes

[Índice](../README.md) · [Catálogo completo](catalogo/README.md) · [Busca por classe](catalogo/busca.md) · [Visual e idioma](../configuracoes/visual-e-idioma.md)

Os componentes compartilhados ficam em [lib/app/widgets/](../../lib/app/widgets/) e são
camadas finas sobre os widgets nativos do Material: cor, borda, raio e tipografia vêm do
tema ([AppTheme](../../lib/app/theme/app_theme.dart)), não de parâmetros. Componentes
específicos de um módulo ficam em `lib/features/<feature>/presentation/widgets/`.

## Como escolher

| Necessidade | Usar | Referência |
|---|---|---|
| Ação principal / secundária / destrutiva / discreta | `AppButton`, `AppButton.secondary`, `AppButton.danger`, `AppButton.text` | [Botões](catalogo/botoes.md) |
| Bloco tocável com leve "afundar" | `AppCard` (`Card` nativo + `onTap`) | [Cards](catalogo/cards.md) |
| Item de lista padrão (título, linha secundária, valor em destaque, detalhes, menu ⋮, cadeado) | `AppListCard` + `AppListCardAction`; `locked: true` para [itens inacessíveis](../configuracoes/planos-e-limites.md#itens-inacessíveis) | [Cards](catalogo/cards.md) |
| Texto | `AppText`, `.title`, `.heading`, `.subtitle`, `.small`, `.caption` | [Textos](catalogo/texto.md) |
| Campo de texto com rótulo acima | `AppTextField` | [Campos](catalogo/campos.md) |
| Valor em reais | `AppMoneyField` (recebe e devolve `Money`, máscara em tempo real) | [Campos](catalogo/campos.md) |
| Lista de opções | `AppDropdown` + `AppDropdownOption` | [Campos](catalogo/campos.md) |
| Busca com espera na digitação | `SearchFieldDebounced` (300 ms) | [Campos](catalogo/campos.md) |
| Data ou intervalo | `AppDatePicker.show` / `.showRange` (bottom sheet com `table_calendar` e atalhos) — no lugar do `showDatePicker` | [Campos](catalogo/campos.md) |
| Conteúdo em bottom sheet | `AppBottomSheet.show(context, child: ...)` (margens, teclado, área segura) | [Modais](catalogo/modais.md) |
| Confirmar ação destrutiva | `ConfirmDialog.show` — título com o nome do item e corpo explicando o impacto, nunca só "Excluir?" | [Modais](catalogo/modais.md) |
| Pedir um texto | `TextInputDialog.show` | [Modais](catalogo/modais.md) |
| Aviso rápido (também de controllers) | `AppFeedback.info/success/error` (`SnackBar` pelo messenger raiz) | [Feedback](catalogo/feedback.md) |
| Falha de `Result` numa ação | `FailurePresenter.show` / `showIfFailure` | [Erros e resultados](../padroes/erros-e-resultados.md) |
| Lista vazia / erro / carregando | `EmptyStateView`, `ErrorStateView`, `LoadingSkeleton`/`LoadingSkeletonList` | [Feedback](catalogo/feedback.md) |
| Filtro de uma escolha em linha | `FilterChipsBar` + `FilterChipOption` (tocar no selecionado desmarca) | [Seleção](catalogo/selecao.md) |
| Seleção múltipla em lista | `SelectableListTile` | [Seleção](catalogo/selecao.md) |
| Ler código de barras | `BarcodeScannerPage` (`scanOnce` / `scanContinuous`) | [Leitura](catalogo/leitura.md), [fluxo](../fluxos/leitura-de-codigo.md) |
| Módulo fora do plano | `LockedFeatureCard`, `PlanFeatures.ensure` | [Planos e limites](../configuracoes/planos-e-limites.md) |
| Logo e nome | `AppLogo`, `AppLogoMark`, `AppWordmark` | [app_logo.dart](../../lib/app/brand/app_logo.dart) |

## Uso básico

Telas leem tudo do tema e mostram texto por chave de tradução:

```dart
AppButton(
  label: 'common.save'.tr,
  onPressed: salvando ? null : salvar,
)
```

`onPressed: null` desabilita o botão. `expanded` (padrão `true`) ocupa a largura toda;
`AppButton.text` não ocupa.

```dart
AppMoneyField(
  label: 'transactions.unitPrice'.tr,
  initialValue: item.unitPrice,
  onChanged: (Money valor) => controller.setPrice(valor),
)
```

```dart
// Exemplo real de boxes_page.dart
final confirmed = await ConfirmDialog.show(
  context,
  title: 'boxes.deleteBoxName'.trParams({'name': box.name}),
  message: 'boxes.doesntDeleteHistoryEntriesRecordedCount'.trParams({'count': '$count'}),
);
if (confirmed) await controller.delete(box.id);
```

## Regras

- **Sem cores fixas nem `isDark`:** use `context.colors`, `context.text`, `context.semantic`.
  Mudar o visual de um componente em todo o app = mudar o tema dele no `AppTheme`.
- **Ícones** sempre `Symbols.*` (Material Symbols), nunca `Icons.*`.
- **Espaçamento e raio** pelos tokens `AppSpacing` e `AppRadius`.
- **Textos** sempre por chave (`'feature.chave'.tr`); ver [idioma](../configuracoes/visual-e-idioma.md#idioma).
- **Feedback** nativo: `SnackBar` (via `AppFeedback`), `AlertDialog`, bottom sheets. Não use
  `Get.snackbar`/`Get.dialog`.
- **Dinheiro** entra e sai como `Money`, nunca `double` ou `String` crus.
- Classes privadas (`_Nome`) são detalhes do arquivo: não reaproveite entre features; se dois
  módulos precisam, promova para `lib/app/widgets/` e regenere o catálogo.

## Testes de componentes

[shared_widgets_theme_test.dart](../../test/app/widgets/shared_widgets_theme_test.dart) monta
os componentes compartilhados nos dois temas; [screens_smoke_test.dart](../../test/app/screens_smoke_test.dart)
abre as telas em tamanho de celular e falha com overflow. Ver [Testes](../padroes/testes.md).
