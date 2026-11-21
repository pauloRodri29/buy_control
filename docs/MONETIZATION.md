# Planos e monetização (levantamento)

Status: Fases 0 e 1 parcialmente implementadas em `lib/features/subscription/`:
- catálogo dos 4 planos;
- assinatura salva no Hive, com pagamento simulado;
- tela "Meu plano" (Configurações → Conta, e o selo no card da conta em Mais);
- limites nos casos de uso `Create*`;
- itens inacessíveis (os N mais antigos ficam liberados) em Boxes, Produtos, Categorias, Tipos, Unidades e Planejamento.

- bloqueio de módulos (`PlanFeatures` / `LockedFeatureCard`):
  - gráficos por categoria e por Box no Início (a evolução mensal fica no Grátis);
  - promoções por item;
  - filtros avançados dos relatórios;
  - comparação A × B;
  - exportação;
  - etiqueta de balança.
- "Repetir no próximo ciclo" foi para o Grátis: já vem ligado por padrão e é o comportamento central do fechamento.

Ainda faltam: o montador do Personalizado e os cupons. Os catálogos padrão são reconhecidos pelo nome (`DefaultCatalogs`), não por um campo `isSystem`. Este documento reúne o que é preciso para publicar o GastoLog nas lojas com plano gratuito, três planos prontos, um plano **Personalizado** com preço calculado a partir dos recursos escolhidos, e cupons.

---

## 1. A restrição que define o desenho: cobrança pelas lojas

Assinatura de recurso digital vendida dentro do app precisa usar o faturamento da loja (Google Play Billing e Apple In-App Purchase). Isso traz três consequências:

1. **Preço fixo por produto.** Cada assinatura é um produto cadastrado no Play Console ou no App Store Connect, com preço definido lá. O app não consegue cobrar "R$ 13,47" calculado na hora.
2. **Cupom não altera o preço livremente.** Desconto na loja é feito por ofertas e códigos promocionais cadastrados antes (Google: *offers* e *promo codes*; Apple: *offer codes* e *promotional offers*).
3. **Taxa da loja.** Em assinaturas, a taxa costuma ser de 15% (Google em assinaturas; Apple no Small Business Program). Os preços sugeridos abaixo já pressupõem isso.

Pagamento fora da loja (Pix, cartão via Stripe ou Mercado Pago) para liberar recurso dentro do app depende da política de cada loja no Brasil, que vem mudando. Antes de considerar essa opção, conferir a política vigente. Este levantamento parte da cobrança pela loja.

### Como o plano Personalizado funciona mesmo assim: base + pesos + escada de preços

O montador com taxa base e soma dos pesos é permitido. A loja não exige que o plano seja fixo. Ela só exige duas coisas:
1. que a cobrança seja de um produto cadastrado nela;
2. que o preço mostrado antes da compra seja o preço cobrado.

O cálculo pode ser livre, desde que o resultado sempre caia num preço que exista na loja. Para isso:

- **Todos os pesos são múltiplos de R$ 1,00** (taxa base, módulos e pacotes). A soma então nunca tem centavos "quebrados".
- **A escada cobre todos os valores possíveis.** Um produto por real, por exemplo `custom_m_05` (R$ 5,00) até `custom_m_40` (R$ 40,00), mais a versão anual. São cerca de 36 produtos mensais e 36 anuais, muito abaixo do limite das lojas. Na Apple, os valores precisam estar na tabela de *price points* do real, que tem preços inteiros nessa faixa.
- **Resultado: o preço é exato, sem arredondamento.** O usuário vê "Base R$ 3 + Planejamento R$ 2 + 10 Boxes R$ 2 = R$ 7,00" e é cobrado R$ 7,00 pelo produto `custom_m_07`.
- **Teto:** se a soma passar do maior degrau, o montador mostra que o Premium sai mais barato e não deixa seguir no Personalizado.
- **O que fica liberado é guardado fora da loja** (no app agora, no backend depois): "compra X = `custom_m_07` + configuração {módulos, pacotes}". A loja só conhece o valor.
- **Mudou a configuração?** O app recalcula e troca de degrau com *upgrade* ou *downgrade* dentro do mesmo grupo de assinatura. A loja cuida do rateio.

Isso passa na revisão porque, para a loja, é uma assinatura comum com preço visível e cobrado por ela. O montador é só a forma de escolher qual degrau comprar.

**Cupom pela mesma lógica.** Um desconto permanente pode simplesmente apontar para um degrau mais baixo: 20% em R$ 15 vira a compra de `custom_m_12`. Um desconto temporário (ex.: 50% nos 3 primeiros meses) usa uma oferta cadastrada na loja, porque depois do período o preço volta sozinho.

Alternativa descartada: um produto de assinatura por módulo (add-ons). Funciona nas duas lojas, mas cada módulo vira uma compra separada com confirmação própria, o que torna a experiência ruim e complica o cupom.

---

## 2. Catálogo: tudo que pode ter peso

Levantado a partir das features atuais e das candidatas ([CANDIDATE_FEATURES.md](CANDIDATE_FEATURES.md)).

### 2.1 Recursos quantitativos (limites)

| Chave | O que conta | Onde aplicar o limite |
|---|---|---|
| `boxes` | Boxes não excluídas | `CreateBox` |
| `products` | Produtos não excluídos | `CreateProduct` e cadastro pelo scanner (`unknown_barcode_sheet`) |
| `categories` | Categorias criadas pelo usuário (as padrão não contam) | `CreateCategory` |
| `productTypes` | Tipos criados pelo usuário | `CreateProductType` |
| `units` | Unidades criadas pelo usuário | `CreateUnit` |
| `planBoards` | Quadros abertos (finalizados e cancelados não contam) | `CreatePlanBoard`, `CreatePlanBoardFromTemplate` |
| `planItemsPerBoard` | Itens em um quadro | `CreatePlanItem`, `MovePlanItem`, `SendPendingItemToBoard` |
| `savedReportPresets` | Filtros de relatório salvos | `ReportPresetRepository` (salvar) |
| `historyMonths` | Meses de histórico visíveis nos Relatórios e no Dashboard | Filtro de período em `GetConsolidatedReport` e Dashboard |

Lançamentos e fechamentos **não** devem ter limite. São o uso principal do app, e limitar isso faz o usuário abandonar o app em vez de assinar.

**Ajuste necessário no modelo:** hoje Categoria, Tipo e Unidade não distinguem o que foi semeado pelo `SeedDefaults` do que o usuário criou. É preciso um campo `isSystem` (ou `origin`) para que os padrões não consumam a cota.

### 2.2 Módulos (liga/desliga)

| Chave | Módulo | Existe hoje? |
|---|---|---|
| `planning` | Planejamento (kanban, pendências, histórico de quadros) | Sim |
| `reportsAdvanced` | Relatórios com vários filtros (várias Boxes, categoria, tipo, produto, faixa de valor) | Sim |
| `reportsCompare` | Comparação Lado A × Lado B | Sim |
| `exportPdf` | PDF, compartilhar e imprimir relatório | Sim |
| `exportCsv` | Exportação CSV | Stub |
| `barcodeScanner` | Scanner de código de barras | Sim |
| `scaleLabel` | Leitura de etiqueta de balança | Sim |
| `carryOver` | "Repetir no próximo ciclo" no fechamento | Sim |
| `discountRules` | Regras de desconto e acréscimo por item | Sim |
| `dashboardCharts` | Gráficos do Dashboard além do total do mês | Sim |
| `boxCustomization` | Ícone e cor da Box | Candidata |
| `priceHistory` | Histórico de preços por produto | Candidata |
| `forecast` | Previsão automática do mês | Candidata |
| `budgets` | Meta por Box e por categoria | Candidata |
| `reminders` | Lembretes e alertas | Candidata |
| `nfceImport` | Importar compra pelo QR Code da NFC-e | Candidata |
| `backupAuto` | Backup automático | Candidata |
| `cloudSync` | Sincronização entre aparelhos | Candidata |
| `sharedBoxes` | Box compartilhada com outras pessoas | Futuro |

**Backup manual (exportar e importar JSON) deve continuar grátis em todos os planos.** O usuário precisa sempre conseguir levar os próprios dados embora (portabilidade, LGPD), e é um argumento de confiança forte na loja. O que se cobra é a comodidade: backup automático e sincronização.

Os módulos futuros entram no catálogo já com `available: false`, aparecendo como "Em breve" no montador de planos.

---

## 3. Planos

### 3.1 Matriz sugerida

| | **Grátis** | **Essencial** | **Pro** | **Premium** |
|---|---|---|---|---|
| Preço mensal | R$ 0 | R$ 6,90 | R$ 12,90 | R$ 19,90 |
| Preço anual | — | R$ 59,90 | R$ 109,90 | R$ 169,90 |
| Boxes | 3 | 10 | 30 | Ilimitado |
| Produtos | 60 | 300 | 1.500 | Ilimitado |
| Categorias / Tipos / Unidades próprias | 5 cada | 20 cada | Ilimitado | Ilimitado |
| Quadros abertos | 1 | 3 | 10 | Ilimitado |
| Itens por quadro | 15 | 50 | 200 | Ilimitado |
| Filtros salvos | 0 | 3 | 20 | Ilimitado |
| Histórico nos relatórios | 3 meses | 12 meses | Tudo | Tudo |
| Lançamentos e fechamentos | Ilimitado | Ilimitado | Ilimitado | Ilimitado |
| Backup manual | ✓ | ✓ | ✓ | ✓ |
| Scanner | ✓ | ✓ | ✓ | ✓ |
| Planejamento | ✓ (limitado) | ✓ | ✓ | ✓ |
| Gráficos do Dashboard | Básico | ✓ | ✓ | ✓ |
| Regras de desconto, repetir ciclo | — | ✓ | ✓ | ✓ |
| Relatórios avançados | — | ✓ | ✓ | ✓ |
| Comparação A × B | — | — | ✓ | ✓ |
| PDF / CSV | — | PDF | ✓ | ✓ |
| Etiqueta de balança | — | — | ✓ | ✓ |
| Histórico de preços, previsão, metas | — | — | ✓ | ✓ |
| Backup automático | — | — | ✓ | ✓ |
| Sincronização, Box compartilhada, NFC-e | — | — | — | ✓ |

Os números são ponto de partida. Como ficam no catálogo remoto (seção 5), dá para ajustar sem publicar versão nova.

Critérios usados:
- **Grátis útil de verdade.** Dá para controlar o mercado do mês inteiro com 3 Boxes. O usuário assina por crescimento ou por um módulo específico, não por bloqueio do básico.
- **Scanner no grátis.** É o que diferencia o app na primeira semana. Vale testar depois se ele converte melhor pago.
- **Premium ancorado em sincronização.** Enquanto a sincronização não existir, lançar só Grátis, Essencial e Pro, ou um Premium com "Em breve" bem claro.
- **Anual com cerca de 2 meses grátis.**

### 3.2 Plano Personalizado

Fórmula:

```
preço = taxa_base
      + Σ preço dos módulos escolhidos
      + Σ (pacotes_extras × preço_do_pacote) por recurso
preço_final = produto da escada com exatamente esse valor (pesos inteiros)
cupom      = degrau mais baixo (permanente) ou oferta da loja (temporário)
```

Os pesos da tabela abaixo estão em centavos quebrados só como referência de proporção. No catálogo final, todos são arredondados para reais inteiros (ou o pacote é redimensionado para que o preço fique inteiro, ex.: +10 Boxes por R$ 1).

- **Taxa base** (sugestão: R$ 3,00/mês). Cobre o custo fixo de ter assinante e evita que o Personalizado saia mais barato que o Essencial com um módulo só.
- **Cada recurso parte do limite do Grátis** e cresce em pacotes (Boxes de 5 em 5, Produtos de 100 em 100…). Pacote é melhor que unidade: o preço fica legível e a escada de degraus não explode.
- **Preço marginal decrescente.** O 1º pacote custa X, do 4º em diante custa 0,7X. Cada recurso também tem uma opção "Ilimitado" com preço fechado.
- **Personalizado um pouco mais caro que o plano pronto equivalente** (10–20%). Se não for, ninguém escolhe os planos prontos. O montador mostra o aviso: "O Pro inclui tudo isso por R$ 12,90 — trocar?"

Pesos sugeridos (mensal):

| Item | Peso |
|---|---|
| Taxa base | R$ 2,90 |
| Planejamento completo | R$ 1,50 |
| Relatórios avançados | R$ 1,50 |
| Comparação A × B | R$ 1,00 |
| PDF / CSV | R$ 1,00 |
| Regras de desconto + repetir ciclo | R$ 0,80 |
| Etiqueta de balança | R$ 0,80 |
| Backup automático | R$ 1,50 |
| Sincronização | R$ 4,00 |
| +5 Boxes | R$ 0,80 (Ilimitado: R$ 3,00) |
| +100 Produtos | R$ 0,50 (Ilimitado: R$ 3,00) |
| +10 Categorias/Tipos/Unidades (cada) | R$ 0,30 |
| +2 Quadros | R$ 0,60 |
| +12 meses de histórico | R$ 1,00 (Tudo: R$ 2,00) |

Anual do Personalizado: `mensal × 10`, arredondado para o degrau anual.

### 3.3 Cupons

O motor de cupons fica no backend. O cupom é traduzido para uma oferta já cadastrada na loja.

Tipos de cupom:

| Tipo | Exemplo | Como vira compra |
|---|---|---|
| Percentual | `GASTO20` = 20% nos 3 primeiros meses | Oferta da loja de 20% com duração de 3 meses |
| Meses grátis | `TESTE30` = 1º mês grátis | Oferta de teste grátis |
| Bônus de recurso | `+50 produtos por 6 meses` | Só no backend: soma ao entitlement, sem mexer no preço |
| Módulo liberado | Planejamento grátis por 2 meses | Só no backend |
| Vitalício / fundador | Primeiros usuários | Entitlement concedido pelo backend, sem loja |

Regras do cupom: validade, máximo de resgates (total e por usuário), planos aos quais se aplica, primeira assinatura ou não, valor mínimo.

Para os percentuais, cadastrar poucas ofertas padronizadas (10%, 20%, 30%, 50%, 1º mês grátis) em cada produto ou degrau. No Google, ofertas com elegibilidade "determinada pelo desenvolvedor". Na Apple, *promotional offers*, que exigem assinatura do servidor e por isso combinam com o backend validando o cupom. O fluxo fica assim: o usuário digita o código, o backend valida e devolve o `offerId`, o app compra com essa oferta e o resumo mostra o desconto aplicado.

---

## 4. Arquitetura no app

Segue a Clean Architecture atual: uma feature nova `lib/features/subscription/`.

### 4.1 Domínio

```dart
enum ResourceKey { boxes, products, categories, productTypes, units,
                   planBoards, planItemsPerBoard, savedReportPresets, historyMonths }

enum FeatureKey { planning, reportsAdvanced, reportsCompare, exportPdf, exportCsv,
                  barcodeScanner, scaleLabel, carryOver, discountRules, dashboardCharts,
                  backupAuto, cloudSync, /* ... */ }

class Limit {                 // null = ilimitado
  final int? max;
}

class Entitlement {
  final String planId;        // free | essential | pro | premium | custom
  final Set<FeatureKey> features;
  final Map<ResourceKey, Limit> limits;
  final DateTime? expiresAt;
  final EntitlementStatus status;  // active, gracePeriod, onHold, expired
  final EntitlementSource source;  // free, store, coupon, lifetime
}

class CustomPlanConfig {
  final Set<FeatureKey> features;
  final Map<ResourceKey, int> extraPacks;   // -1 = ilimitado
}

class PriceQuote {
  final Money subtotal, discount, total;
  final String storeProductId;   // degrau da escada
  final String? storeOfferId;    // cupom
  final List<PriceLine> lines;   // para o resumo
  final String? cheaperPlanSuggestion;
}
```

`Money` em centavos (já existe) é usado em todo cálculo de preço.

Casos de uso:
- `GetEntitlement`, `WatchEntitlement`
- `CheckQuota(resource)` → `Result<void>`
- `GetUsage()`, para a tela "Meu plano"
- `QuoteCustomPlan(config, coupon?)` → `PriceQuote`. Cálculo puro e testável, lendo o catálogo.
- `ValidateCoupon(code)`, `Purchase(quote)`, `RestorePurchases()`

### 4.2 Onde o bloqueio entra

- **Nova falha:** `final class PlanLimitFailure extends AppFailure { final ResourceKey? resource; final FeatureKey? feature; }`. O `FailurePresenter` reconhece essa falha e abre o paywall em vez de mostrar um snackbar.
- **Limites no domínio.** Os usecases `Create*` listados em 2.1 recebem um `QuotaGuard` e o chamam antes de gravar. Assim a regra vale para tela, scanner e importação, e testa com fakes como o resto.
- **Módulos na apresentação** (`FeatureGate`): widget e route guard que trocam o conteúdo por um card "Disponível no Pro" ou abrem o paywall. Ações sensíveis (exportar PDF, comparação) também checam no usecase.

### 4.3 Regras de rebaixamento: itens inacessíveis

Quando a assinatura vence ou o usuário troca para um plano menor:

- **Nenhum dado é apagado.**
- **O que passa do limite fica inacessível automaticamente.** O usuário não escolhe quais itens ficam liberados; o app decide por uma regra fixa.
- **Regra de quais ficam liberados:** os **N mais antigos** (por `createdAt`), sendo N o limite do plano. É estável: criar ou editar não muda quem está liberado, e o usuário consegue prever o resultado. Exemplo: 12 Boxes no Grátis (limite 3) → as 3 primeiras criadas ficam liberadas e as outras 9 ficam inacessíveis.
- **Inacessível significa:**
  - aparece na lista com cadeado e esmaecido (para o usuário saber que existe e o que ganha assinando), mas não abre, não edita, não exclui e não recebe lançamento;
  - não aparece em seletores (escolher produto, categoria, unidade, Box nos filtros de relatório, quadro de destino);
  - o scanner que encontra um produto inacessível avisa "Produto bloqueado no seu plano" em vez de usá-lo;
  - tocar no item abre a sheet de planos.
- **Itens dentro de um limite por pai** (itens por quadro): liberados os N primeiros pela posição na coluna; os demais ficam com cadeado.
- **Módulo bloqueado:** o módulo inteiro fica inacessível (ex.: a aba Planejar mostra os quadros com cadeado e o convite para assinar).
- **Liberar de novo:** ao assinar ou subir de plano, tudo volta na hora. Se o usuário apagar um item liberado, o próximo mais antigo inacessível é liberado.
- **O bloqueio é calculado, não gravado.** Nenhum campo `locked` é salvo nos registros. Um `AccessPolicy` cruza o entitlement atual com a lista ordenada e responde `isAccessible(item)`. Assim, mudar de plano nunca exige migrar dados e não há risco de o registro ficar "preso".
- **Relatórios e Dashboard:** os totais históricos continuam contando os lançamentos fechados de itens inacessíveis. Se não contassem, os relatórios mudariam ao rebaixar o plano, o que quebra a regra "relatório gerado hoje continua o mesmo amanhã". O que fica bloqueado é filtrar por esse item ou abrir o detalhe dele. *(Decisão a confirmar — a alternativa é esconder também dos totais.)*
- **Backup manual** exporta tudo, inclusive o inacessível. Os dados continuam sendo do usuário.
- **Importação de backup** acima do limite é permitida. Depois de importar vale a mesma regra.
- **Carência** (pagamento falhou, renovação pendente): o plano continua ativo com aviso durante o período de carência, e só depois aplica o bloqueio.

### 4.4 Modo simulado (sem backend, agora)

O sistema de planos funciona de ponta a ponta já, com dados salvos localmente e pagamento simulado. Quando o backend existir, só as implementações das interfaces são trocadas, como já acontece com o `FakeAuthRepository`.

| Interface (domínio) | Agora: implementação local | Depois |
|---|---|---|
| `PlanCatalogRepository` | Catálogo embarcado no app (planos, pesos, limites, escada) | Catálogo remoto com o embarcado como fallback |
| `EntitlementRepository` | Assinatura ativa salva no Hive (box `subscription`) | Entitlement vindo do backend/RevenueCat, com cache no Hive |
| `BillingGateway` | `FakeBillingGateway`: abre uma sheet "Pagamento simulado" com Aprovar / Recusar / Cancelar, sem cobrança | `RevenueCatBillingGateway` |
| `CouponRepository` | Lista de cupons de teste embarcada, com controle de resgate no Hive | Validação no backend |

Detalhes do modo simulado:
- **Compra simulada** gera uma assinatura com `source: simulated`, data de início e `expiresAt` (1 mês ou 1 ano) e grava no Hive vinculada ao usuário logado (o e-mail do login fake).
- **Renovação e vencimento** são calculados localmente pela data. Para testar sem esperar, um **painel de desenvolvedor** (escondido, ex.: tocar 7 vezes na versão em "Sobre") permite: vencer agora, avançar 1 mês, entrar em carência, trocar de plano sem pagar e limpar a assinatura.
- **Faixa "Modo de teste"** visível no paywall e em "Meu plano", para não haver dúvida de que nada foi cobrado.
- **Segurança da publicação:** o `FakeBillingGateway` e o painel só são registrados fora do modo release, ou por uma flag de build (`--dart-define=BILLING=fake`). Uma build para a loja nunca pode liberar plano sem compra real.
- **Seu uso pessoal:** você assina o Pro (ou o que quiser) pelo pagamento simulado e usa o app normalmente, já sentindo os limites e os bloqueios.

### 4.5 Offline

O app é offline-first. O entitlement fica em cache no Hive (`subscription` box) com `expiresAt` e um token assinado pelo backend. Sem internet, o plano em cache vale até `expiresAt + 7 dias`, e só depois cai para o Grátis. Num aparelho com root alguém consegue burlar as travas locais. Isso é aceitável para recursos locais. Os recursos de nuvem (sincronização, backup automático) são validados no servidor, então não são burláveis.

---

## 5. Backend e serviços

Hoje o login é fake e não existe servidor. Para cobrar, o mínimo é:

| Peça | Por quê | Opções |
|---|---|---|
| **Autenticação real** | Vincular a compra a uma conta e restaurar em outro aparelho | Firebase Auth ou Supabase Auth, com Google/Apple Sign-In. Entra como `ApiAuthRepository`, já previsto na arquitetura |
| **Validação de compras** | Não confiar no app para dizer que pagou; receber renovações e cancelamentos | **RevenueCat** (`purchases_flutter`) resolve recibos, notificações das lojas, entitlements e ofertas. A alternativa é validar na mão (Play Developer API + RTDN, App Store Server API + Notifications V2) |
| **Catálogo remoto** | Mudar pesos, limites e planos sem nova versão | JSON versionado no backend ou Remote Config, com uma cópia embarcada no app como fallback |
| **Configuração do Personalizado** | Guardar "degrau X = configuração Y" | Tabela no backend, gravada após a compra confirmada |
| **Cupons** | Validar código, controlar resgates, assinar oferta da Apple | Função no backend (Cloud Functions / Edge Functions) |

Recomendação: **RevenueCat + Supabase (ou Firebase)**. O RevenueCat elimina a parte mais trabalhosa e arriscada (recibos e renovações) e é gratuito até um certo faturamento mensal. Conferir os termos atuais antes de decidir.

Fluxo de compra do Personalizado:

```
App: monta config → QuoteCustomPlan → (cupom? backend valida → offerId)
App: compra degrau via RevenueCat (com offerId)
Loja → RevenueCat → webhook → backend grava config + entitlement
App: recebe entitlement atualizado → cache local → libera
```

---

## 6. Telas

1. **Paywall / "Planos"** (Mais → Meu plano, e aberto pelos bloqueios): alternância mensal/anual, 3 cards dos planos prontos com o recomendado destacado, botão "Monte o seu plano", campo de cupom, "Restaurar compras", links de Termos e Privacidade e o texto de renovação automática exigido pelas lojas.
2. **Montador do Personalizado:** lista de módulos com interruptor e preço ao lado; recursos com stepper de pacotes ou "Ilimitado"; barra inferior fixa com o total atualizado ao vivo, que abre o resumo linha a linha (base, módulos, pacotes, cupom, total); aviso de plano pronto mais barato quando houver.
3. **Meu plano:** plano atual, renovação, barras de uso ("Boxes 2/3", "Produtos 48/60"), botão de gerenciar assinatura (abre a página da loja).
4. **Bloqueio em contexto:** ao bater o limite, uma bottom sheet curta ("Você chegou a 3 Boxes no plano Grátis") com o plano mais barato que resolve e o atalho para o montador.
5. **Avisos de estado:** carência, pagamento pendente, plano expirado.

O item "Sincronização — Em breve" no menu Mais passa a apontar para o módulo no catálogo.

---

## 7. Lojas, legal e operação

- **Apple:** compra de conteúdo digital via IAP (diretriz 3.1.1); assinaturas com descrição clara, preço, período e renovação (3.1.2); botão "Restaurar compras" obrigatório; Sign in with Apple obrigatório se houver outro login social.
- **Google Play:** Play Billing Library na versão exigida no momento; formulário de segurança de dados (Data safety).
- **Documentos:** Política de Privacidade e Termos de Uso publicados, com link no app e nas lojas.
- **LGPD:** com login real, os dados de conta passam a ser tratados pelo serviço. A exclusão de conta pelo próprio app é exigência das duas lojas.
- **Fiscal:** receber das lojas exige conta de pagamento (CNPJ/MEI ou pessoa física, com implicações diferentes). Vale conversar com um contador antes de publicar.
- **Seus dados atuais:** criar um entitlement "Fundador/vitalício" para a sua conta e para os primeiros testadores.

---

## 8. Fases sugeridas

| Fase | Entrega | Depende de backend? |
|---|---|---|
| **0. Fundação local** | Feature `subscription` com enums, catálogo embarcado, `EntitlementRepository` no Hive, `QuotaGuard` nos `Create*`, `PlanLimitFailure`, `AccessPolicy` (itens inacessíveis), `FeatureGate`, campo `isSystem` nos catálogos. Testes de unidade das cotas, da regra dos N mais antigos e do rebaixamento | Não |
| **1. Planos com pagamento simulado** | Paywall com os 3 planos, montador do Personalizado com preço exato, cupons de teste, `FakeBillingGateway`, tela "Meu plano" com uso, painel de desenvolvedor, faixa "Modo de teste" | Não |
| **2. Conta real + lojas** | Auth real, RevenueCat no lugar do `FakeBillingGateway`, produtos e escada cadastrados nas lojas, restaurar compras, cache offline, entitlement de fundador | Sim |
| **3. Backend do Personalizado e cupons** | Catálogo remoto, configuração do Personalizado e cupons validados no servidor, ofertas das lojas | Sim |
| **4. Módulos de nuvem** | Backup automático e sincronização entrando no catálogo como recursos pagos | Sim |

As Fases 0 e 1 são feitas agora, sem infraestrutura nenhuma: o app passa a funcionar por plano, com tudo salvo localmente. As Fases 2 em diante só trocam implementações de interface.

---

## 9. Decisões em aberto

1. **Lançar com o Personalizado ou só com os 3 planos?** Muitas opções reduzem a conversão (paradoxo da escolha). Sugestão: lançar com os 3 planos (Fase 1) e liberar o Personalizado como "Monte o seu" secundário na Fase 2, medindo se ele canibaliza o Pro.
2. **Teste grátis** do Pro por 7 dias na primeira assinatura?
3. **Scanner no Grátis ou pago?**
4. **Quantos degraus na escada** (mais degraus = preço mais justo, mais produtos para manter nas lojas).
5. **Valores finais** dos planos e pesos, depois de olhar concorrentes na loja.
6. **Itens inacessíveis nos totais:** continuam contando nos relatórios e no Dashboard (proposta atual) ou somem também dos totais?
