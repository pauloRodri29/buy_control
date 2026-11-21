# Módulo: Lançamentos

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [carry_over_switch](#carry-over-switch)
- [discount_rule_editor](#discount-rule-editor)
- [transaction_detail_sheet](#transaction-detail-sheet)

<a id="carry-over-switch"></a>

## carry_over_switch

**Código:** [lib/features/transactions/presentation/widgets/carry_over_switch.dart](../../../lib/features/transactions/presentation/widgets/carry_over_switch.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### CarryOverSwitch

Opção "Repetir no próximo ciclo" de um lançamento: quando a Box for
fechada, os lançamentos marcados voltam para ela como novos lançamentos
abertos (ver `CloseBox`); os desmarcados ficam só no histórico.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const CarryOverSwitch({super.key, required this.value, required this.onChanged});

// Tipos dos campos públicos declarados nesta classe.
  final bool value;
  final ValueChanged<bool> onChanged;
```

</details>

**Onde usar como referência:**

- [lib/features/transactions/presentation/pages/purchase_summary_step.dart](../../../lib/features/transactions/presentation/pages/purchase_summary_step.dart)
- [lib/features/transactions/presentation/pages/standalone_entry_sheet.dart](../../../lib/features/transactions/presentation/pages/standalone_entry_sheet.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
CarryOverSwitch(value: _draft.carryOver, onChanged: (v) => setState(() => _draft.carryOver = v))
```

<a id="discount-rule-editor"></a>

## discount_rule_editor

**Código:** [lib/features/transactions/presentation/widgets/discount_rule_editor.dart](../../../lib/features/transactions/presentation/widgets/discount_rule_editor.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### DiscountRuleEditor

Seletor de promoção de um item: o usuário escolhe o tipo ("Leve 4 por
R$ 10", "Leve 3 pague 2", ...) e preenche só os parâmetros daquele
tipo. O valor do desconto em si é calculado por quem usa o widget
(`DiscountRule.calculate`), nunca digitado à mão.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const DiscountRuleEditor({super.key, this.initialRule, required this.onChanged});

// Tipos dos campos públicos declarados nesta classe.
  final DiscountRule? initialRule;
  final ValueChanged<DiscountRule?> onChanged;
```

</details>

**Onde usar como referência:**

- [lib/features/transactions/presentation/pages/item_details_step.dart](../../../lib/features/transactions/presentation/pages/item_details_step.dart)
- [lib/features/transactions/presentation/pages/standalone_entry_sheet.dart](../../../lib/features/transactions/presentation/pages/standalone_entry_sheet.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
DiscountRuleEditor(
              initialRule: item.discountRule,
              onChanged: (rule) => widget.onChanged(
                rule == null
                    ? widget.item.copyWith(clearDiscountRule: true, discount: Money.zero)
                    : widget.item.copyWith(discountRule: rule),
              ),
            )
```

<a id="transaction-detail-sheet"></a>

## transaction_detail_sheet

**Código:** [lib/features/transactions/presentation/widgets/transaction_detail_sheet.dart](../../../lib/features/transactions/presentation/widgets/transaction_detail_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### TransactionDetailSheet

Mostra os detalhes completos de um lançamento: itens, quantidades,
preços unitários e o cálculo final (subtotal, desconto, acréscimo,
total) — sempre lido dos getters da entidade, nunca recalculado aqui.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const TransactionDetailSheet({super.key, required this.transaction});

// Tipos dos campos públicos declarados nesta classe.
  final TransactionEntity transaction;
```

</details>

**Integração:** nenhuma chamada direta encontrada fora deste arquivo. Pode ser usado só por herança, `static` ou dentro do próprio arquivo; confira a fonte antes de adotar ou remover.

