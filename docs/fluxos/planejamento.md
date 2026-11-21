# Planejamento

[Fluxos](README.md) · [Relatórios](relatorios.md) · [Planos e limites](../configuracoes/planos-e-limites.md)

Quadros no estilo kanban para compras futuras. **Entrada:** aba Planejar, com três abas
internas: Quadros, Pendências e Histórico.

## Quadros

1. **+** no topo cria um quadro (`PlanBoardFormSheet`): título, descrição, data de
   previsão e meta opcional. Os quadros ficam ordenados pela data de previsão; com um
   único quadro, ele ocupa a largura da tela.
2. Menu ⋮ do topo: mostrar/esconder arquivados e itens já comprados.
3. "Adicionar item" na coluna: título, descrição e valor estimado opcional. Itens sem
   quadro ficam na coluna "Sem quadro".
4. Segurar e arrastar move o item entre colunas e posições; perto da borda, rola sozinho.
5. Tocar no círculo marca como comprado (data de hoje) ou desfaz.
6. O cabeçalho mostra planejado, comprado e progresso da meta (`PlanBoardProgress`,
   calculado, não gravado), com aviso quando a meta é ultrapassada.
7. Menu ⋮ do quadro (`PlanBoardAction`): editar, finalizar, cancelar, arquivar/desarquivar,
   excluir. Ao excluir, o usuário escolhe se os itens vão para "Sem quadro" ou são apagados.

## Finalizar ou cancelar

Com tudo comprado, o topo do quadro mostra **Finalizar**; pelo menu dá para finalizar ou
cancelar a qualquer momento. `FinishPlanBoardSheet` resolve tudo antes:

- cada item não comprado vai para **outro quadro aberto** ou para **Pendências**, com um
  motivo (sem estoque, caro demais, não precisei, deixei para depois, outro com texto livre);
  sem outros quadros abertos, todos vão para Pendências;
- itens comprados sem valor podem receber o valor pago.

`FinishPlanBoard` grava `closedAt` (finalizado) ou `cancelledAt` (cancelado). É definitivo:
o quadro vai para o Histórico. O que já foi comprado continua nos relatórios.

## Pendências e Histórico

- **Pendências:** itens não comprados com motivo e quadro de origem. Deslizar para a
  esquerda envia para um quadro aberto (volta a "a comprar", `SendPendingItemToBoard`);
  para a direita exclui, depois de confirmar.
- **Histórico:** quadros finalizados/cancelados com total gasto e comparação com a meta.
  No detalhe: ajustar data e valor pago de cada compra, "Usar como modelo"
  (`CreatePlanBoardFromTemplate`: quadro novo com os mesmos itens desmarcados) e
  "Excluir do histórico" (apaga as compras do quadro, que deixam de contar nos relatórios,
  e mantém as Pendências).

## Regras de dados

- Posição do item é `double`: mover calcula o ponto médio entre vizinhos; a coluna é
  renumerada só quando a diferença fica menor que `1e-6` (`PlanItemPositions`).
- Valor que conta nos relatórios: `PlanItemEntity.value` = valor pago, ou o estimado.
- Um item só entra nos [Relatórios](relatorios.md) depois de comprado, no mês da data da compra.
- Limites do plano: quadros **abertos** e itens **por quadro** (ver
  [Planos e limites](../configuracoes/planos-e-limites.md)). Mover ou enviar item para um
  quadro cheio também é recusado.

| Alterar | Fonte |
|---|---|
| Quadros: criar, finalizar, modelo, excluir | [plan_board_usecases.dart](../../lib/features/planning/domain/usecases/plan_board_usecases.dart) |
| Itens: criar, mover, comprar, pendência | [plan_item_usecases.dart](../../lib/features/planning/domain/usecases/plan_item_usecases.dart) |
| Ordem na coluna | [plan_item_positions.dart](../../lib/features/planning/domain/usecases/plan_item_positions.dart) |
| Motivos de não compra | [finish_plan_board_sheet.dart](../../lib/features/planning/presentation/widgets/finish_plan_board_sheet.dart) |
| Tela | [planning_page.dart](../../lib/features/planning/presentation/pages/planning_page.dart), [planning_controller.dart](../../lib/features/planning/presentation/controllers/planning_controller.dart) |
| Testes | [planning_usecases_test.dart](../../test/features/planning/planning_usecases_test.dart), [planning_report_test.dart](../../test/features/planning/planning_report_test.dart) |
