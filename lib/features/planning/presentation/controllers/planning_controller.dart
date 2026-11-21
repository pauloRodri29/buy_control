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

/// Estado do Planejamento: quadros abertos (kanban), Pendências e
/// Histórico (quadros finalizados ou cancelados).
class PlanningController extends GetxController {
  final GetPlanBoards getBoards;
  final CreatePlanBoard createBoard;
  final CreatePlanBoardFromTemplate createBoardFromTemplate;
  final UpdatePlanBoard updateBoard;
  final DeletePlanBoard deleteBoard;
  final FinishPlanBoard finishBoard;
  final GetPlanItems getItems;
  final CreatePlanItem createItem;
  final UpdatePlanItem updateItem;
  final DeletePlanItem deleteItem;
  final TogglePlanItemPurchased togglePurchased;
  final MovePlanItem moveItem;
  final SendPendingItemToBoard sendPendingToBoard;

  PlanningController({
    required this.getBoards,
    required this.createBoard,
    required this.createBoardFromTemplate,
    required this.updateBoard,
    required this.deleteBoard,
    required this.finishBoard,
    required this.getItems,
    required this.createItem,
    required this.updateItem,
    required this.deleteItem,
    required this.togglePurchased,
    required this.moveItem,
    required this.sendPendingToBoard,
  });

  ViewStatus status = ViewStatus.initial;
  String? errorMessage;

  List<PlanBoardEntity> _allBoards = [];
  List<PlanItemEntity> _items = [];

  bool showArchived = false;
  bool hidePurchased = false;

  /// Quadros abertos exibidos no kanban, ordenados pela data de previsão.
  List<PlanBoardEntity> get boards =>
      _allBoards.where((b) => b.isOpen && (showArchived || !b.isArchived)).toList();

  /// Quadros disponíveis como destino ao mover/criar itens: abertos e não
  /// arquivados.
  List<PlanBoardEntity> get activeBoards => _allBoards.where((b) => b.isOpen && !b.isArchived).toList();

  /// Destinos para os itens não comprados de [board] ao finalizá-lo.
  List<PlanBoardEntity> destinationsFor(PlanBoardEntity board) =>
      activeBoards.where((b) => b.id != board.id).toList();

  /// Quadros finalizados/cancelados, do mais recente para o mais antigo.
  List<PlanBoardEntity> get history =>
      _allBoards.where((b) => b.isFinished).toList()..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));

  /// Itens não comprados de quadros finalizados, mais recentes primeiro.
  List<PlanItemEntity> get pendingItems =>
      _items.where((i) => i.isPending).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  PlanBoardEntity? boardById(String? id) => id == null ? null : _allBoards.firstWhereOrNull((b) => b.id == id);

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

    final boardsResult = await getBoards(includeArchived: true);
    final itemsResult = await getItems();

    final failure = boardsResult.failureOrNull ?? itemsResult.failureOrNull;
    if (failure != null) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    } else {
      _allBoards = boardsResult.dataOrNull!;
      _items = itemsResult.dataOrNull!;
      status = ViewStatus.success;
    }
    update();
  }

  /// Nada para mostrar no kanban (sem quadros abertos nem itens soltos).
  bool get isKanbanEmpty => boards.isEmpty && !hasInboxItems;

  /// Itens exibidos na coluna [boardId] (`null` = "Sem quadro").
  List<PlanItemEntity> itemsOf(String? boardId) {
    final column = PlanItemPositions.column(_items, boardId);
    return hidePurchased ? column.where((i) => !i.isPurchased).toList() : column;
  }

  /// Progresso sempre considera todos os itens, inclusive os ocultos.
  PlanBoardProgress progressOf(PlanBoardEntity? board) {
    return PlanBoardProgress.of(board, PlanItemPositions.column(_items, board?.id));
  }

  /// Itens de um quadro do Histórico, incluindo os que viraram Pendência.
  List<PlanItemEntity> historyItemsOf(String boardId) =>
      _items.where((i) => i.boardId == boardId).toList()..sort((a, b) => a.position.compareTo(b.position));

  PlanBoardProgress historyProgressOf(PlanBoardEntity board) =>
      PlanBoardProgress.of(board, historyItemsOf(board.id));

  bool get hasInboxItems => PlanItemPositions.column(_items, null).isNotEmpty;

  int itemCountOf(String boardId) => PlanItemPositions.column(_items, boardId).length;

  /// Itens ainda não comprados do quadro (ignora o filtro "ocultar comprados").
  List<PlanItemEntity> unpurchasedItemsOf(String boardId) =>
      PlanItemPositions.column(_items, boardId).where((i) => !i.isPurchased).toList();

  /// Itens comprados do quadro que estão sem valor algum.
  List<PlanItemEntity> purchasedWithoutValueOf(String boardId) =>
      PlanItemPositions.column(_items, boardId).where((i) => i.isPurchased && i.value == null).toList();

  void toggleShowArchived() {
    showArchived = !showArchived;
    update();
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

  Future<String?> addBoardFromTemplate(
    PlanBoardEntity template, {
    required String title,
    String? description,
    Money? goal,
    required DateTime targetDate,
  }) {
    return _run(createBoardFromTemplate(
      template,
      title: title,
      description: description,
      goal: goal,
      targetDate: targetDate,
    ));
  }

  Future<String?> editBoard(PlanBoardEntity board) => _run(updateBoard(board));

  Future<String?> setArchived(PlanBoardEntity board, bool archived) {
    return _run(updateBoard(board.copyWith(isArchived: archived)));
  }

  Future<String?> removeBoard(String id, {required bool deleteItems}) {
    return _run(deleteBoard(id, deleteItems: deleteItems));
  }

  Future<String?> finish(
    PlanBoardEntity board, {
    required PlanBoardEnding ending,
    required Map<String, PendingItemDestination> destinations,
    required Map<String, Money> paidValues,
  }) {
    return _run(finishBoard(board, ending: ending, destinations: destinations, paidValues: paidValues));
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

  Future<String?> sendPendingTo(PlanItemEntity item, String boardId) =>
      _run(sendPendingToBoard(item, boardId: boardId));
}
