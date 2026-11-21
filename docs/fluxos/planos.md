# Planos e assinatura

[Fluxos](README.md) · [Planos e limites](../configuracoes/planos-e-limites.md)

O app funciona por plano, com tudo salvo no aparelho e **pagamento simulado**: nenhuma
cobrança acontece. Valores, limites e módulos de cada plano estão em
[Planos e limites](../configuracoes/planos-e-limites.md).

## Entradas

- Mais → selo do plano no card da conta → **Meu plano**;
- Configurações → Conta → Meu plano;
- qualquer bloqueio (`PlanLimitPrompt`, `LockedFeatureCard`) → **Planos**.

## Meu plano (`MyPlanPage`)

Plano atual, vencimento, barras de uso por recurso ("Boxes 2/3"), chave de renovação
automática e, no modo simulado, uma faixa "Modo de teste" e as ações de teste:
**simular vencimento agora** e **remover assinatura** (volta ao Grátis como se nunca
tivesse assinado).

## Planos (`PlansPage`)

1. Alterna mensal/anual (anual ≈ 10 mensalidades).
2. Cards dos planos prontos (o Pro vem destacado como recomendado) com módulos e limites.
3. Campo de cupom (`CouponField`): valida na hora (`ValidateCoupon`); o cupom fica aplicado
   enquanto o usuário compara os planos.
4. "Monte o seu plano" abre o **Personalizado**.
5. Assinar → `SimulatedPaymentSheet` com **Aprovar / Recusar / Cancelar** → `PurchasePlan`
   grava a assinatura. Recusar mostra erro; cancelar não mostra nada.

## Personalizado (`CustomPlanBuilderPage`)

Taxa base + módulos escolhidos + pacotes de recursos acima do Grátis (ou "ilimitado").
Barra inferior com o total ao vivo. Se um plano pronto cobrir tudo pelo mesmo preço ou
menos, o montador sugere trocar (`cheaperStandardPlan`). Acima do teto
(R$ 40/mês) a compra é recusada.

## Cupons de teste

| Cupom | Desconto | Restrição |
|---|---|---|
| `BEMVINDO10` | 10% | — |
| `GASTOLOG20` | 20% | — |
| `PRIMEIRA50` | 50% | só para quem nunca assinou |
| `MONTE30` | 30% | só no Personalizado |
| `MENOS5` | R$ 5,00 | — |
| `VENCIDO` | 90% | vencido (para testar a mensagem) |

Cada cupom vale **uma vez por usuário**. O desconto fica gravado em `pricePaid` e vale para
as renovações.

## Vencimento e renovação

- Assinatura ativa enquanto `agora < expiresAt`; o período começa na hora da compra
  (mensal = +1 mês, anual = +1 ano).
- Com renovação ligada e pagamento simulado, `GetEntitlement` renova sozinho ao abrir
  (avança `expiresAt` período a período até passar de agora).
- Com renovação desligada, o plano segue até o vencimento e depois volta ao Grátis
  (`Entitlement.expired`).
- Ao mudar de plano, as listas recalculam os bloqueios na hora (`addPlanListener`).

## Trocar o pagamento simulado pela loja

O `InitialBinding` registra `FakeBillingGateway`. Para a loja (Google Play / App Store, ou
um serviço como RevenueCat), implemente `BillingGateway` e registre no lugar; com backend,
troque também `SubscriptionRepository` e `CouponRepository`. Nenhuma tela muda. Uma build
para a loja nunca deve registrar o `FakeBillingGateway`.

| Alterar | Fonte |
|---|---|
| Compra, renovação, cupom | [subscription_usecases.dart](../../lib/features/subscription/domain/usecases/subscription_usecases.dart), [coupon_usecases.dart](../../lib/features/subscription/domain/usecases/coupon_usecases.dart) |
| Cupons de teste | [local_coupon_repository.dart](../../lib/features/subscription/data/repositories/local_coupon_repository.dart) |
| Pagamento simulado | [fake_billing_gateway.dart](../../lib/features/subscription/data/billing/fake_billing_gateway.dart), [simulated_payment_sheet.dart](../../lib/features/subscription/presentation/widgets/simulated_payment_sheet.dart) |
| Estado do plano e ações de teste | [subscription_controller.dart](../../lib/features/subscription/presentation/controllers/subscription_controller.dart) |
| Telas | [my_plan_page.dart](../../lib/features/subscription/presentation/pages/my_plan_page.dart), [plans_page.dart](../../lib/features/subscription/presentation/pages/plans_page.dart), [custom_plan_builder_page.dart](../../lib/features/subscription/presentation/pages/custom_plan_builder_page.dart) |
| Registro (DI) | [initial_binding.dart](../../lib/app/bindings/initial_binding.dart) |
| Testes | [subscription_test.dart](../../test/features/subscription/subscription_test.dart), [custom_plan_and_coupon_test.dart](../../test/features/subscription/custom_plan_and_coupon_test.dart) |
