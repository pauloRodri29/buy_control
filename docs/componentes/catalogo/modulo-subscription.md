# Módulo: Planos

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [coupon_field](#coupon-field)
- [plan_badge](#plan-badge)
- [plan_feature_row](#plan-feature-row)
- [plan_limit_prompt](#plan-limit-prompt)
- [plan_summary_card](#plan-summary-card)
- [simulated_payment_sheet](#simulated-payment-sheet)

<a id="coupon-field"></a>

## coupon_field

**Código:** [lib/features/subscription/presentation/widgets/coupon_field.dart](../../../lib/features/subscription/presentation/widgets/coupon_field.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### CouponField

"Tem um cupom?": abre o campo do código; aplicado, vira um selo com o
desconto e o botão de remover. O cupom fica no controller, então vale
na tela de planos e no montador.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const CouponField({super.key});

static String describe(Coupon coupon);

```

</details>

**Onde usar como referência:**

- [lib/features/subscription/presentation/pages/custom_plan_builder_page.dart](../../../lib/features/subscription/presentation/pages/custom_plan_builder_page.dart)
- [lib/features/subscription/presentation/pages/plans_page.dart](../../../lib/features/subscription/presentation/pages/plans_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
CouponField()
```

<a id="plan-badge"></a>

## plan_badge

**Código:** [lib/features/subscription/presentation/widgets/plan_badge.dart](../../../lib/features/subscription/presentation/widgets/plan_badge.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanBadge

Selo com o nome do plano (card da conta, Configurações, cards de plano).

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanBadge({super.key, required this.plan});

// Tipos dos campos públicos declarados nesta classe.
  final PlanDefinition plan;
```

</details>

**Onde usar como referência:**

- [lib/features/more/presentation/pages/more_page.dart](../../../lib/features/more/presentation/pages/more_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanBadge(plan: subscription.plan)
```

<a id="plan-feature-row"></a>

## plan_feature_row

**Código:** [lib/features/subscription/presentation/widgets/plan_feature_row.dart](../../../lib/features/subscription/presentation/widgets/plan_feature_row.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanFeatureRow

Um módulo do plano: ✓ quando incluído, cadeado quando não, e
"Em breve" para o que ainda não existe no app.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanFeatureRow({super.key, required this.feature, required this.included, this.dense = false});

// Tipos dos campos públicos declarados nesta classe.
  final FeatureKey feature;
  final bool included;
  final bool dense;
```

</details>

**Onde usar como referência:**

- [lib/features/subscription/presentation/pages/my_plan_page.dart](../../../lib/features/subscription/presentation/pages/my_plan_page.dart)
- [lib/features/subscription/presentation/pages/plans_page.dart](../../../lib/features/subscription/presentation/pages/plans_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanFeatureRow(feature: feature, included: plan.has(feature))
```

<a id="plan-limit-prompt"></a>

## plan_limit_prompt

**Código:** [lib/features/subscription/presentation/widgets/plan_limit_prompt.dart](../../../lib/features/subscription/presentation/widgets/plan_limit_prompt.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanLimitPrompt

Aviso de que o plano não permite a ação, com o atalho para os planos.
Usado pelo `FailurePresenter` (limite atingido) e ao tocar num item
bloqueado.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
static Future<void> show(String message, {String title = 'subscription.planLimit'});

static Future<void> showLocked(String planName);

```

</details>

**Onde usar como referência:**

- [lib/app/errors/failure_presenter.dart](../../../lib/app/errors/failure_presenter.dart)
- [lib/features/subscription/presentation/plan_features.dart](../../../lib/features/subscription/presentation/plan_features.dart)
- [lib/features/subscription/presentation/plan_locks.dart](../../../lib/features/subscription/presentation/plan_locks.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanLimitPrompt.show(present(failure))
```

<a id="plan-summary-card"></a>

## plan_summary_card

**Código:** [lib/features/subscription/presentation/widgets/plan_summary_card.dart](../../../lib/features/subscription/presentation/widgets/plan_summary_card.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### PlanSummaryCard

Atalho para "Meu plano" (no Perfil): ícone do plano, nome e situação
da assinatura. Atualiza sozinho quando o plano muda.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const PlanSummaryCard({super.key});

```

</details>

**Onde usar como referência:**

- [lib/features/auth/presentation/pages/profile_page.dart](../../../lib/features/auth/presentation/pages/profile_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
PlanSummaryCard()
```

<a id="simulated-payment-sheet"></a>

## simulated_payment_sheet

**Código:** [lib/features/subscription/presentation/widgets/simulated_payment_sheet.dart](../../../lib/features/subscription/presentation/widgets/simulated_payment_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### SimulatedPaymentSheet

"Checkout" do pagamento simulado: mostra o que seria cobrado e deixa
aprovar, recusar ou cancelar. Nenhum valor é cobrado.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const SimulatedPaymentSheet({super.key, required this.request});

static Future<SimulatedPaymentDecision> ask(PurchaseRequest request);

// Tipos dos campos públicos declarados nesta classe.
  final PurchaseRequest request;
```

</details>

**Integração:** nenhuma chamada direta encontrada fora deste arquivo. Pode ser usado só por herança, `static` ou dentro do próprio arquivo; confira a fonte antes de adotar ou remover.

