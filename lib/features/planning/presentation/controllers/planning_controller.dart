import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_progress.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_board_usecases.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_positions.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_usecases.dart';
import 'package:get/get.dart';

class PlanningController extends GetxController {
  final GetPlanBoards getBoards;
  final CreatePlanBoard createBoard;
  final UpdatePlanBoard updateBoard;
  final DeletePlanBoard deleteBoard;
  final ClosePlanBoard closeBoard;
  final ReopenPlanBoard reopenBoard;
  final GetPlanItems getItems;
  final CreatePlanItem createItem;
  final UpdatePlanItem updateItem;
  final DeletePlanItem deleteItem;
  final TogglePlanItemPurchased togglePurchased;
  final MovePlanItem moveItem;

  PlanningController({
    required this.getBoards,
    required this.createBoard,
    required this.updateBoard,
    required this.deleteBoard,
    required this.closeBoard,
    required this.reopenBoard,
    required this.getItems,
    required this.createItem,
    required this.updateItem,
    required this.deleteItem,
    required this.togglePurchased,
    required this.moveItem,
  });

  ViewStatus status = ViewStatus.initial;
  String? errorMessage;

  /// Quadros visíveis, já ordenados pela data de previsão.
  List<PlanBoardEntity> boards = [];
  List<PlanItemEntity> _items = [];

  bool showArchived = false;
  bool hidePurchased = false;

  /// Quadros disponíveis como destino ao mover/criar itens (sem arquivados).
  List<PlanBoardEntity> get activeBoards => boards.where((b) => !b.isArchived).toList();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      status = ViewStatus.loading;
      update();
    }

    final boardsResult = await getBoards(includeArchived: showArchived);
    final itemsResult = await getItems();

    final failure = boardsResult.failureOrNull ?? itemsResult.failureOrNull;
    if (failure != null) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    } else {
      boards = boardsResult.dataOrNull!;
      _items = itemsResult.dataOrNull!;
      status = boards.isEmpty && _items.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }
    update();
  }

  /// Itens exibidos na coluna [boardId] (`null` = "Sem quadro").
  List<PlanItemEntity> itemsOf(String? boardId) {
    final column = PlanItemPositions.column(_items, boardId);
    return hidePurchased ? column.where((i) => !i.isPurchased).toList() : column;
  }

  /// Progresso sempre considera todos os itens, inclusive os ocultos.
  PlanBoardProgress progressOf(PlanBoardEntity? board) {
    return PlanBoardProgress.of(board, PlanItemPositions.column(_items, board?.id));
  }

  bool get hasInboxItems => _items.any((i) => i.boardId == null);

  int itemCountOf(String boardId) => _items.where((i) => i.boardId == boardId).length;

  void toggleShowArchived() {
    showArchived = !showArchived;
    load(silent: true);
  }

  void toggleHidePurchased() {
    hidePurchased = !hidePurchased;
    update();
  }

  Future<String?> _run(Future<Result<dynamic>> action) async {
    final result = await action;
    return result.fold((_) {
      load(silent: true);
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  // Quadros

  Future<String?> addBoard({
    required String title,
    String? description,
    Money? goal,
    required DateTime targetDate,
  }) {
    return _run(createBoard(title: title, description: description, goal: goal, targetDate: targetDate));
  }

  Future<String?> editBoard(PlanBoardEntity board) => _run(updateBoard(board));

  Future<String?> setArchived(PlanBoardEntity board, bool archived) {
    return _run(updateBoard(board.copyWith(isArchived: archived)));
  }

  Future<String?> removeBoard(String id, {required bool deleteItems}) {
    return _run(deleteBoard(id, deleteItems: deleteItems));
  }

  Future<String?> close(PlanBoardEntity board, {required DateTime purchasedAt}) {
    return _run(closeBoard(board, purchasedAt: purchasedAt));
  }

  Future<String?> reopen(PlanBoardEntity board) => _run(reopenBoard(board));

  /// Itens ainda não comprados do quadro (ignora o filtro "ocultar comprados").
  List<PlanItemEntity> pendingItemsOf(String boardId) {
    return PlanItemPositions.column(_items, boardId).where((i) => !i.isPurchased).toList();
  }

  // Itens

  Future<String?> addItem({String? boardId, required String title, String? description, Money? estimatedValue}) {
    return _run(createItem(
      boardId: boardId,
      title: title,
      description: description,
      estimatedValue: estimatedValue,
    ));
  }

  Future<String?> editItem(PlanItemEntity item) => _run(updateItem(item));

  Future<String?> removeItem(String id) => _run(deleteItem(id));

  Future<String?> togglePurchasedOf(PlanItemEntity item) => _run(togglePurchased(item));

  Future<String?> move(PlanItemEntity item, {String? toBoardId, String? beforeItemId}) {
    final sameSpot = item.boardId == toBoardId && beforeItemId == null && itemsOf(toBoardId).lastOrNull?.id == item.id;
    if (sameSpot) return Future.value(null);
    return _run(moveItem(item, toBoardId: toBoardId, beforeItemId: beforeItemId));
  }
}
