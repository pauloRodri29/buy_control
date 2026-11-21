# Fechamento de ciclo

[Fluxos](README.md) · [Boxes e lançamentos](boxes-e-lancamentos.md) · [Relatórios](relatorios.md)

**Entrada:** detalhe da Box → ícone de cadeado.

1. Sem lançamentos abertos → aviso de que não há nada para fechar.
2. Usuário escolhe a **data de referência** (só a data; padrão hoje).
3. Diálogo de confirmação com quantidade de itens e total, avisando que é definitivo.
4. `CloseBox` executa **tudo ou nada**:
   1. cria o `BoxClosureEntity` (nome da Box no momento, data de referência, total,
      contagem de lançamentos e itens, observação opcional);
   2. marca `closureId` e `closureReferenceDate` em cada lançamento aberto (congelado);
   3. copia como **novo lançamento aberto** cada um marcado com "Repetir no próximo ciclo"
      (`carryOver`): mesmos itens, quantidades, preços e promoções, ids novos, data de hoje.
   Se qualquer gravação falhar, desfaz o que já foi gravado e a Box volta ao estado anterior.
5. Ícone de histórico → `BoxClosuresPage` (data de referência, nº de itens, total) →
   `BoxClosureDetailPage` com a lista somente leitura.

Fechamentos são definitivos: não há reabrir nem editar.

## Por que o fechamento importa

- **Balanço:** Início e Relatórios contam só lançamentos com `closureId`, datados por
  `accountingDate` (= data de referência; Fechamentos antigos sem esse campo usam a data
  do lançamento). Editar um lançamento aberto nunca altera um relatório já gerado.
- **Sem duplicar dados:** o detalhe do Fechamento consulta os lançamentos com aquele
  `closureId`, que já são imutáveis.

| Alterar | Fonte |
|---|---|
| Regra do fechamento e cópia | [close_box.dart](../../lib/features/box_closures/domain/usecases/close_box.dart) |
| Entidade | [box_closure_entity.dart](../../lib/features/box_closures/domain/entities/box_closure_entity.dart) |
| Data contábil do lançamento | [transaction_entity.dart](../../lib/features/transactions/domain/entities/transaction_entity.dart) |
| Telas | [box_closures_page.dart](../../lib/features/box_closures/presentation/pages/box_closures_page.dart), [box_closure_detail_page.dart](../../lib/features/box_closures/presentation/pages/box_closure_detail_page.dart) |
| Testes | [close_box_test.dart](../../test/features/box_closures/close_box_test.dart) |
