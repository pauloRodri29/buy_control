import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';

/// Regras de ordenação dos itens dentro de uma coluna (quadro ou "Sem
/// quadro").
class PlanItemPositions {
  PlanItemPositions._();

  /// Itens da coluna [boardId], ordenados por posição. Pendências não
  /// pertencem a nenhuma coluna do kanban.
  static List<PlanItemEntity> column(Iterable<PlanItemEntity> items, String? boardId) {
    return items.where((i) => i.boardId == boardId && !i.isPending).toList()..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Posição para adicionar um item ao final da coluna [boardId].
  static double nextPosition(Iterable<PlanItemEntity> items, String? boardId) {
    final siblings = column(items, boardId);
    return siblings.isEmpty ? 0 : siblings.last.position + 1;
  }
}
