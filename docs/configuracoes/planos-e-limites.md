# Planos e limites

[Configurações](README.md) · [Fluxo de planos](../fluxos/planos.md)

Cada usuário tem um **entitlement**: o plano em vigor (`Entitlement.resolve`), calculado a
partir da assinatura salva. Sem assinatura, ou vencida, vale o Grátis. Há dois tipos de
regra: **limites de quantidade** (`ResourceKey`) e **módulos** liga/desliga (`FeatureKey`).

## Planos prontos

| | Grátis | Essencial | Pro | Premium |
|---|---|---|---|---|
| Mensal | R$ 0 | R$ 6,90 | R$ 12,90 | R$ 19,90 |
| Anual | — | R$ 59,90 | R$ 109,90 | R$ 169,90 |
| Boxes | 3 | 10 | 30 | ilimitado |
| Produtos | 60 | 300 | 1.500 | ilimitado |
| Categorias / Tipos / Unidades próprias (cada) | 5 | 20 | ilimitado | ilimitado |
| Quadros abertos | 1 | 3 | 10 | ilimitado |
| Itens por quadro | 15 | 50 | 200 | ilimitado |

`null` (ou ausente) no mapa de limites = ilimitado. Lançamentos, Fechamentos e filtros de
relatório salvos **não** têm limite.

## Módulos

| `FeatureKey` | O que libera | A partir de | Onde é conferido |
|---|---|---|---|
| `planning` | Planejamento | Grátis | sem trava (sempre incluído) |
| `backupManual` | backup em arquivo/GitHub | Grátis | sem trava |
| `barcodeScanner` | leitor de código | Grátis | sem trava |
| `carryOver` | "Repetir no próximo ciclo" | Grátis | sem trava |
| `dashboardCharts` | gráficos por categoria e por Box no Início | Essencial | `DashboardPage` |
| `discountRules` | promoções por item | Essencial | `ItemDetailsStep`, `StandaloneEntrySheet` |
| `reportsAdvanced` | filtros avançados dos relatórios | Essencial | `ReportFiltersSheet` |
| `exportPdf` | exportar relatório | Essencial | `ReportExportSheet` |
| `reportsCompare` | comparação A × B | Pro | `ReportsPage` |
| `scaleLabel` | etiqueta de balança | Pro | `scan_items_flow.dart` |
| `priceHistory`, `budgets`, `backupAuto` | "Em breve" (`available: false`) | Pro | — |
| `cloudSync` | "Em breve" | Premium | — |

## Como a regra é aplicada

| Peça | Papel |
|---|---|
| [QuotaGuard](../../lib/features/subscription/domain/usecases/quota_guard.dart) | os casos de uso `Create*` (Box, produto, categoria, tipo, unidade, quadro, item) e `MovePlanItem`/`SendPendingItemToBoard` perguntam `ensureCanAdd` antes de gravar; no limite devolvem `PlanLimitFailure`. Vale para tela, leitor e qualquer outro chamador |
| [ResourceInventory](../../lib/features/subscription/domain/resource_inventory.dart) | lista o que conta: excluídos não contam; Boxes e quadros **arquivados contam**; catálogos padrão não contam; quadros só abertos; itens por quadro só nas colunas abertas, sem Pendências |
| [PlanFeatures](../../lib/features/subscription/presentation/plan_features.dart) | `has` decide o que mostrar; `ensure` bloqueia uma ação e abre o aviso; `LockedFeatureCard` ocupa o lugar do módulo |
| [FailurePresenter](../../lib/app/errors/failure_presenter.dart) | `PlanLimitFailure` abre `PlanLimitPrompt` (com atalho para os planos) em vez de snackbar |

Sem `SubscriptionController` registrado (testes isolados), `PlanFeatures.has` libera tudo e o
`QuotaGuard` é opcional nos casos de uso.

<a id="itens-inacessíveis"></a>

## Itens inacessíveis

Quando o plano diminui (venceu, trocou para menor), **nada é apagado**:

- ficam liberados os **N primeiros** (os mais antigos por `createdAt`; nos itens de quadro,
  os primeiros da coluna), sendo N o limite; o resto fica inacessível
  ([AccessPolicy](../../lib/features/subscription/domain/access_policy.dart));
- o usuário não escolhe quais; criar ou editar não muda quem está liberado;
- inacessível aparece com cadeado e esmaecido, não abre, não edita, e tocar abre o aviso
  do plano; o leitor de código avisa em vez de usar o produto;
- o bloqueio é **calculado, não gravado**: subir de plano libera tudo na hora;
- backup exporta tudo, inclusive o inacessível; importar acima do limite é permitido.

Listas com bloqueio usam o mixin [PlanLocks](../../lib/features/subscription/presentation/plan_locks.dart):
Boxes, Produtos, Categorias, Tipos, Unidades e quadros do Planejamento. Chame
`refreshLocks()` no `load()`, use `isLocked(id)` na tela; o `load()` roda de novo quando o
plano muda.

## Plano Personalizado

[CustomPlanPricing](../../lib/features/subscription/domain/custom_plan_pricing.dart): parte
dos limites e módulos do Grátis e soma, por mês:

| Item | Preço |
|---|---|
| Taxa base | R$ 3 |
| Gráficos do Início, filtros avançados | R$ 2 cada |
| Promoções, comparação A×B, exportar PDF, etiqueta de balança | R$ 1 cada |
| +5 Boxes | R$ 1 por pacote (até 6) · ilimitado R$ 4 |
| +100 Produtos | R$ 1 (até 10) · ilimitado R$ 5 |
| +10 Categorias / Tipos / Unidades (cada) | R$ 1 (até 5) · ilimitado R$ 2 |
| +2 Quadros | R$ 1 (até 5) · ilimitado R$ 3 |
| +25 itens por quadro | R$ 1 (até 6) · ilimitado R$ 2 |

Mínimo R$ 5, teto R$ 40/mês; anual = 10 mensalidades. Todos os pesos são reais inteiros
para o preço sempre cair num degrau que exista na loja (`custom_m_05` … `custom_m_40`),
quando houver cobrança real.

## Mudar um plano

1. Valores e módulos: [plan_catalog.dart](../../lib/features/subscription/domain/plan_catalog.dart).
2. Recurso novo com limite: valor em `ResourceKey`, caso em `ResourceInventory.items`,
   `ensureCanAdd` no `Create*`, pacote em `CustomPlanPricing.packs` e, se for lista, `PlanLocks`.
3. Módulo novo: valor em `FeatureKey`, conjunto no `PlanCatalog`, trava com `PlanFeatures`
   e, se for vendável avulso, preço em `CustomPlanPricing.modulePrices`.
4. Textos em `assets/i18n` (`subscription.*`) e testes em
   [test/features/subscription](../../test/features/subscription/).
