# Boxes e lançamentos

[Fluxos](README.md) · [Fechamento](fechamento.md) · [Leitura de código](leitura-de-codigo.md) · [Armazenamento](../configuracoes/armazenamento.md)

Uma **Box** é um contexto nomeado de gasto ("Mercado", "Farmácia"). Ela nunca "acaba":
recebe lançamentos para sempre, e o ciclo de compras é encerrado pelo [Fechamento](fechamento.md).

## Lista de Boxes

**Entrada:** aba Boxes.

- Busca, ordenação por nome, data ou valor (`BoxSort`), criar/editar (`BoxFormSheet`:
  só o nome; `BoxEntity` já tem `description`, `icon` e `color`, sem campo na tela),
  arquivar/desarquivar e excluir.
- Excluir é lógico (`deletedAt`), não apaga o registro.
- Boxes acima do limite do plano aparecem com cadeado e não abrem
  ([itens inacessíveis](../configuracoes/planos-e-limites.md#itens-inacessíveis)).
- Criar além do limite devolve `PlanLimitFailure` (aviso com atalho para os planos).

## Detalhe da Box

O cabeçalho mostra o total do **ciclo aberto**. A lista de lançamentos tem busca e
ordenação (`TransactionSort`: mais novos, mais antigos, maior/menor valor, nome, quantidade).
No topo: cadeado (fechar ciclo) e histórico (Fechamentos).

## Adicionar itens

**Entrada:** detalhe da Box → "Adicionar itens" (`AddItemsChoiceSheet`).

| Caminho | Etapas |
|---|---|
| Selecionar produtos | catálogo com busca e filtro por categoria (`ProductPickerSheet`) → editor de itens → resumo → confirmar |
| Escanear produtos | câmera em modo carrinho → editor de itens → resumo → confirmar ([Leitura de código](leitura-de-codigo.md)) |
| Lançamento avulso | `StandaloneEntrySheet`: título, valor, quantidade, unidade, promoção, categoria/tipo opcionais, data, observação e "Repetir no próximo ciclo" |

1. **Editor de itens** (`ItemDetailsStep`): quantidade (−/+), preço unitário (vem do preço
   de referência do produto, editável), unidade, promoção, acréscimo; remover item;
   "Adicionar produto" reabre o catálogo; "Escanear" abre a câmera.
2. **Resumo** (`PurchaseSummaryStep`): desconto/acréscimo gerais e a chave
   "Repetir no próximo ciclo" (`CarryOverSwitch`, ligada por padrão). "Editar itens" (ou
   tocar num item) volta ao editor sem perder nada.
3. **Confirmar** grava o lançamento aberto (`closureId = null`). Fechar ou voltar em
   qualquer etapa não grava nada: todo o estado vive num `PurchaseDraft` em memória.

**Avulso salvo como produto:** a chave "salvar como produto" confere o limite de produtos do
plano já ao ser ligada. Também é possível vincular o avulso a um produto existente.

## Editar e excluir

- Tocar num lançamento **aberto** reabre o mesmo fluxo (`openEditTransactionFlow` →
  `UpdateTransaction`); avulso abre o formulário avulso preenchido.
- Lançamento **fechado** é imutável: `UpdateTransaction`/`DeleteTransaction` recusam no
  domínio, não só na tela.

## Promoções por item

`DiscountRule` calcula o desconto a partir de quantidade e preço. O valor calculado é
gravado em `TransactionItemEntity.discount` (retrato do momento) junto da regra, e
recalculado quando quantidade ou preço mudam. Exige o módulo `discountRules`
(Essencial em diante); no Grátis aparece o card de bloqueio.

| Tipo (`DiscountType`) | Exemplo |
|---|---|
| `fixed` | R$ 2,00 de desconto |
| `percent` | 10% |
| `bundlePrice` | Leve 4 por R$ 10,00 (o que sobra fora do grupo sai pelo preço normal) |
| `buyXPayY` | Leve 3, pague 2 |
| `wholesale` | A partir de 6 un., R$ 3,49 cada |

O desconto nunca é negativo nem maior que o subtotal; parâmetros inválidos dão desconto zero.
O total do lançamento é `soma dos itens − desconto + acréscimo`.

| Alterar | Fonte |
|---|---|
| Regras de Box | [usecases de boxes](../../lib/features/boxes/domain/usecases/) |
| Lista e detalhe | [boxes_controller.dart](../../lib/features/boxes/presentation/controllers/boxes_controller.dart), [box_detail_controller.dart](../../lib/features/boxes/presentation/controllers/box_detail_controller.dart) |
| Fluxo de adicionar/editar | [add_items_flow.dart](../../lib/features/transactions/presentation/add_items_flow.dart), [purchase_draft.dart](../../lib/features/transactions/presentation/purchase_draft.dart) |
| Gravação dos itens | [save_purchase_items.dart](../../lib/features/transactions/domain/usecases/save_purchase_items.dart), [create_transaction.dart](../../lib/features/transactions/domain/usecases/create_transaction.dart) |
| Guarda de imutabilidade | [update_transaction.dart](../../lib/features/transactions/domain/usecases/update_transaction.dart), [delete_transaction.dart](../../lib/features/transactions/domain/usecases/delete_transaction.dart) |
| Promoções | [discount_rule.dart](../../lib/features/transactions/domain/entities/discount_rule.dart) |
| Ordenação | [transaction_sort.dart](../../lib/features/transactions/domain/usecases/transaction_sort.dart) |
