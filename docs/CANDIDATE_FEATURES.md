# Melhorias candidatas

Avaliação das próximas funcionalidades do Buy Control, feita a partir do código atual. O app é uma ferramenta de **planejamento e previsão de gastos**. Por isso, as propostas foram priorizadas pelo quanto ajudam o usuário a prever e controlar o que vai gastar, e pelo quanto do código já existente elas reaproveitam.

Nenhuma delas exige mudar a arquitetura. Cada uma cabe na estrutura atual: uma feature com `domain` → `data` → `presentation`, `Result`/`AppFailure`, `Money` e GetX.

> Ideias estruturais de longo prazo (API, multiusuário, autenticação real) estão em [FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md).

## Resumo

| # | Melhoria | Impacto | Esforço | O que já existe |
|---|---|---|---|---|
| 1 | Histórico de preços por produto | Alto | Baixo | `TransactionItemEntity.productId` + `unitPrice` |
| 2 | Previsão automática do mês | Alto | Baixo | Fechamentos com total e data de referência |
| 3 | Meta por Box e por categoria | Alto | Baixo | `PlanBoardProgress` (metas dos quadros) |
| 4 | Ícone e cor da Box | Médio | Baixo | Campos `icon` e `color` em `BoxEntity` |
| 5 | Item do quadro vira lançamento | Alto | Médio | Planejamento + fluxo de lançamento |
| 6 | Lembretes e alertas | Médio | Médio | Datas de previsão e de Fechamento |
| 7 | Backup automático | Médio | Médio | `ExportBackup` |
| 8 | Importar compra pelo QR Code da NFC-e | Muito alto | Alto | `mobile_scanner` e fluxo de lançamento |
| 9 | Sincronização em nuvem | Alto | Alto | `SyncableFields` em todas as entidades |

**Ordem recomendada:** 1 → 2 → 3, depois 5. As três primeiras usam só dados que já existem e reforçam a previsão. A 5 fecha o ciclo entre planejar e comprar.

---

## 1. Histórico de preços por produto

**Problema:** o usuário não sabe se o preço de hoje está caro ou barato, e o preço de referência do produto fica desatualizado.

**Proposta:** na edição de um produto e na hora de lançar o item, mostrar:
- o último preço pago, o menor e a média;
- a variação em relação à compra anterior (por exemplo, "+12% desde 10/10");
- um gráfico simples da evolução, reaproveitando o `fl_chart`.

Além disso, oferecer **atualizar o preço de referência** com o último preço pago.

**O que já existe:**
- Cada `TransactionItemEntity` guarda `productId`, `unitPrice`, `unitId` e a data do lançamento.
- Lançamentos fechados são imutáveis, então o histórico não muda depois.

**O que falta:**
- Um caso de uso `GetProductPriceHistory(productId)` que leia o `TransactionRepository`.
- Um widget de resumo de preços.

**Cuidados:** comparar só itens com a mesma unidade, para não misturar o preço do kg com o da unidade. Promoções devem aparecer separadas: o preço efetivo é o total do item dividido pela quantidade.

## 2. Previsão automática do mês

**Problema:** hoje a previsão vem só do Planejamento. Os gastos que se repetem (mercado, farmácia) não entram na projeção.

**Proposta:** calcular a média dos últimos N Fechamentos de cada Box (padrão 3) e mostrar no Início:
- "Mercado deve fechar em ~R$ 1.200 este mês";
- o total previsto do mês = previsão das Boxes + itens pendentes dos quadros com data no mês.

**O que já existe:**
- `BoxClosureEntity` tem `total` e `referenceDate`.
- `PlanningReportSummary.forecastPending` já soma a previsão do Planejamento.

**O que falta:**
- Um caso de uso `GetMonthForecast`.
- Um card de previsão no Dashboard.
- Opcionalmente, a previsão como coluna no relatório.

**Cuidados:**
- Boxes com menos de 2 Fechamentos não têm histórico suficiente. Mostrar "sem histórico" em vez de um número enganoso.
- Boxes que fecham com frequência diferente (semanal, mensal) precisam ser normalizadas pelo período.

## 3. Meta por Box e por categoria

**Problema:** só os quadros de planejamento têm meta. O gasto do dia a dia não tem limite.

**Proposta:** permitir uma meta mensal opcional por Box e por categoria. A meta aparece como barra de progresso na lista de Boxes, no Início e nos Relatórios, com destaque quando o gasto passar de 80% e de 100%.

**O que já existe:**
- O cálculo de meta, saldo e percentual em `PlanBoardProgress`, que pode ser generalizado.
- As cores semânticas `success`/`warning`/`error` do tema.

**O que falta:**
- O campo `monthlyGoal` (`Money?`) em `BoxEntity` e `CategoryEntity`, com migração tolerante a registros antigos.
- O campo no formulário.
- O widget de progresso compartilhado.

**Cuidados:**
- O Dashboard só considera lançamentos fechados. Para acompanhar a meta durante o mês, o progresso precisa somar também o ciclo aberto, e a tela deve deixar isso claro.

## 4. Ícone e cor da Box

**Problema:** na lista, todas as Boxes parecem iguais.

**Proposta:** escolher um ícone e uma cor no formulário da Box. Eles aparecem no `AppListCard` (`leading`) e nos gráficos por Box.

**O que já existe:**
- Os campos `icon` e `color` em `BoxEntity`, que hoje não são usados pelo formulário.
- O parâmetro `leading` do `AppListCard`.

**O que falta:** um seletor com uma lista curta de ícones Lucide e uma paleta derivada do tema (`AppSemanticColors.chartSeries`), para funcionar nos temas claro e escuro.

## 5. Item do quadro vira lançamento

**Problema:** marcar um item do Planejamento como comprado só conta no relatório. O gasto não aparece na Box onde a compra aconteceu, e se o usuário também lançar na Box, o valor é contado duas vezes.

**Proposta:** ao marcar um item como comprado (ou ao fechar um quadro), oferecer **"Lançar em uma Box"**:
1. o usuário escolhe a Box;
2. o lançamento é criado com o título e o valor do item;
3. o item guarda o `transactionId` gerado.

O relatório passa a ignorar os itens que já têm lançamento, porque eles entram pela Box.

**O que já existe:**
- `TogglePlanItemPurchased` e `ClosePlanBoard`.
- O fluxo de lançamento avulso.
- `GetConsolidatedReport`, que já separa Boxes e Planejamento.

**O que falta:**
- O campo `transactionId` em `PlanItemEntity`.
- A escolha da Box no sheet de fechamento.
- A regra de exclusão no relatório.

**Cuidados:**
- Se o lançamento for excluído, o item volta a ser contado pelo Planejamento.
- O backup precisa preservar o vínculo entre item e lançamento.

## 6. Lembretes e alertas

**Proposta:** notificações locais para:
- um quadro com data de previsão em 3 dias e itens pendentes;
- uma Box com lançamentos abertos há mais de N dias ("Fechar Mercado?");
- uma meta (item 3) que passou de 80% ou de 100%.

Em Configurações → Preferências, uma opção para ligar ou desligar cada tipo de aviso.

**O que já existe:** as datas de previsão, de lançamento e de Fechamento, e as preferências guardadas no `AppMetaStore`.

**O que falta:**
- O pacote `flutter_local_notifications`.
- O pedido de permissão (Android 13+ e iOS).
- O agendamento ao salvar um quadro.
- Um ponto de reagendamento na abertura do app.

## 7. Backup automático

**Proposta:** gerar o backup sozinho (diário ou semanal), guardar os últimos N arquivos na pasta do app e mostrar em Configurações → Dados a data do último backup, com a opção de restaurar qualquer um.

**O que já existe:** `ExportBackup` e `ImportBackup` completos, incluindo o Planejamento.

**O que falta:**
- Agendar o backup na abertura do app, comparando com a data do último backup no `AppMetaStore`.
- A rotação dos arquivos.
- A lista de backups locais.

**Cuidados:**
- Um backup na própria pasta do app não protege contra a perda do aparelho. Para isso, ver o item 9 ou exportar manualmente.

## 8. Importar compra pelo QR Code da NFC-e

**Problema:** lançar uma compra grande item a item é o passo mais trabalhoso do app.

**Proposta:** ler o QR Code da nota fiscal do consumidor (NFC-e) e importar de uma vez a data, o total e os itens (nome, quantidade, unidade e valor), associando cada item a produtos do catálogo pelo código de barras (GTIN) quando ele vier na nota.

**O que já existe:**
- O leitor (`mobile_scanner`).
- O `PurchaseDraft` e o editor de itens.
- `FindProductByBarcode`.
- O cadastro de produto a partir de um código desconhecido.

**O que falta:**
- Buscar e interpretar a página de consulta da SEFAZ do estado.
- Tela de revisão dos itens importados antes de gravar.

**Riscos:**
- Cada estado tem um formato de página e ele muda sem aviso.
- Exige internet.
- Começar por um estado e manter o parser isolado atrás de uma interface (`NfceReader`), para que uma falha nunca impeça o lançamento manual.

## 9. Sincronização em nuvem

**Proposta:** ter os mesmos dados em mais de um aparelho e um backup fora do aparelho.

**O que já existe:**
- Todas as entidades têm `syncStatus`, `version` e `deletedAt` (exclusão lógica).
- O menu Mais já mostra "Sincronização · Em breve".

**O que falta:**
- Um backend.
- Autenticação real no lugar do `FakeAuthRepository`.
- Repositórios remotos.
- A fila de envio.
- A resolução de conflitos.

Os detalhes da arquitetura estão em [FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md).

---

## Pendências menores encontradas na avaliação

- **Exportação em CSV:** aparece no sheet de exportação, mas `AppReportExporter.exportToCsv` ainda devolve `NotImplementedFailure`. É barata de implementar com os dados do `ConsolidatedReport`.
- **"Sincronização" no menu Mais:** é um item que só mostra "Em breve". Pode sair do menu até existir, para não frustrar o usuário.
