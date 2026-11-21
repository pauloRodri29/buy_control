import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_positions.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';

AppFailure? _validateBoard({required String title, Money? goal}) {
  if (!Validators.isNotBlank(title)) {
    return ValidationFailure('planning.boardTitleRequired'.tr);
  }
  if (goal != null && goal.isNegative) {
    return ValidationFailure('planning.goalCantNegative'.tr);
  }
  return null;
}

String? _normalizeText(String? value) => Validators.isNotBlank(value) ? value!.trim() : null;

class GetPlanBoards {
  final PlanBoardRepository repository;
  const GetPlanBoards(this.repository);

  Future<Result<List<PlanBoardEntity>>> call({bool includeArchived = false}) {
    return repository.getAll(includeArchived: includeArchived);
  }
}

class CreatePlanBoard {
  final PlanBoardRepository repository;
  final QuotaGuard? quota;
  const CreatePlanBoard(this.repository, {this.quota});

  Future<Result<PlanBoardEntity>> call({
    required String title,
    String? description,
    Money? goal,
    required DateTime targetDate,
  }) async {
    final failure = _validateBoard(title: title, goal: goal);
    if (failure != null) return Failure(failure);

    if (await quota?.ensureCanAdd(ResourceKey.planBoards) case final limit?) return Failure(limit);

    final now = DateTime.now();
    final board = PlanBoardEntity(
      id: IdGenerator.generate(),
      title: title.trim(),
      description: _normalizeText(description),
      goal: goal == null || goal.isZero ? null : goal,
      targetDate: DateTime(targetDate.year, targetDate.month, targetDate.day),
      createdAt: now,
      updatedAt: now,
    );

    final result = await repository.create(board);
    return result.fold((_) => Success(board), (f) => Failure(f));
  }
}

class UpdatePlanBoard {
  final PlanBoardRepository repository;
  const UpdatePlanBoard(this.repository);

  Future<Result<void>> call(PlanBoardEntity board) async {
    final failure = _validateBoard(title: board.title, goal: board.goal);
    if (failure != null) return Failure(failure);
    return repository.update(board);
  }
}

enum PlanBoardEnding { finish, cancel }

/// O que fazer com um item não comprado ao finalizar/cancelar um quadro:
/// ir para outro quadro aberto ([toBoardId]) ou virar Pendência ([reason]).
class PendingItemDestination {
  final String? toBoardId;
  final String? reason;

  const PendingItemDestination.board(String boardId)
      : toBoardId = boardId,
        reason = null;

  const PendingItemDestination.pending(String this.reason) : toBoardId = null;
}

/// Finaliza (ou cancela) um quadro. É definitivo: o quadro sai do kanban e
/// vai para o Histórico.
///
/// - Cada item não comprado precisa de um destino em [destinations]: outro
///   quadro aberto (vai para o final dele) ou Pendências, com um motivo.
/// - [paidValues] registra o valor pago de itens comprados (normalmente os
///   que estavam sem valor).
class FinishPlanBoard {
  final PlanBoardRepository boardRepository;
  final PlanItemRepository itemRepository;
  const FinishPlanBoard({required this.boardRepository, required this.itemRepository});

  Future<Result<void>> call(
    PlanBoardEntity board, {
    PlanBoardEnding ending = PlanBoardEnding.finish,
    Map<String, PendingItemDestination> destinations = const {},
    Map<String, Money> paidValues = const {},
    DateTime? now,
  }) async {
    if (board.isFinished) return Failure(ValidationFailure('planning.boardAlreadyHistory'.tr));

    final itemsResult = await itemRepository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);
    final boardsResult = await boardRepository.getAll(includeArchived: true);
    if (boardsResult case Failure(:final failure)) return Failure(failure);

    final all = itemsResult.dataOrNull!;
    final openBoardIds = {
      for (final b in boardsResult.dataOrNull!)
        if (b.isOpen && b.id != board.id) b.id,
    };
    final boardItems = PlanItemPositions.column(all, board.id);

    final nextPositions = <String, double>{};
    final updates = <PlanItemEntity>[];

    for (final item in boardItems) {
      if (item.isPurchased) {
        final paid = paidValues[item.id];
        if (paid != null && paid.isNegative) {
          return Failure(ValidationFailure('planning.amountPaidCantNegative'.tr));
        }
        if (paid != null && !paid.isZero) updates.add(item.copyWith(paidValue: paid));
        continue;
      }

      final destination = destinations[item.id];
      if (destination == null) {
        return Failure(ValidationFailure('planning.chooseDestinationTitle'.trParams({'title': item.title})));
      }

      final toBoardId = destination.toBoardId;
      if (toBoardId != null) {
        if (!openBoardIds.contains(toBoardId)) {
          return Failure(ValidationFailure('planning.boardChosenNoLongerOpenTitle'.trParams({'title': item.title})));
        }
        final position = nextPositions[toBoardId] ?? PlanItemPositions.nextPosition(all, toBoardId);
        nextPositions[toBoardId] = position + 1;
        updates.add(item.copyWith(boardId: toBoardId, position: position));
      } else {
        if (!Validators.isNotBlank(destination.reason)) {
          return Failure(ValidationFailure('planning.enterReasonNotBuyingTitle'.trParams({'title': item.title})));
        }
        updates.add(item.copyWith(notPurchasedReason: destination.reason!.trim()));
      }
    }

    if (updates.isNotEmpty) {
      final itemsUpdate = await itemRepository.updateAll(updates);
      if (itemsUpdate case Failure(:final failure)) return Failure(failure);
    }

    final at = now ?? DateTime.now();
    return boardRepository.update(switch (ending) {
      PlanBoardEnding.finish => board.copyWith(closedAt: at),
      PlanBoardEnding.cancel => board.copyWith(cancelledAt: at),
    });
  }
}

/// Cria um quadro novo a partir de outro (normalmente do Histórico), com
/// os mesmos itens, todos desmarcados e sem valor pago. Substitui o
/// "reabrir": o quadro original continua intacto no Histórico.
class CreatePlanBoardFromTemplate {
  final CreatePlanBoard createBoard;
  final PlanItemRepository itemRepository;
  const CreatePlanBoardFromTemplate({required this.createBoard, required this.itemRepository});

  Future<Result<PlanBoardEntity>> call(
    PlanBoardEntity template, {
    required String title,
    String? description,
    Money? goal,
    required DateTime targetDate,
  }) async {
    final itemsResult = await itemRepository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);

    final created = await createBoard(title: title, description: description, goal: goal, targetDate: targetDate);
    if (created case Failure(:final failure)) return Failure(failure);
    final board = created.dataOrNull!;

    // Inclui as Pendências que saíram deste quadro (mantêm o boardId de origem).
    final source = itemsResult.dataOrNull!.where((i) => i.boardId == template.id).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final now = DateTime.now();
    for (var i = 0; i < source.length; i++) {
      final item = source[i];
      final result = await itemRepository.create(PlanItemEntity(
        id: IdGenerator.generate(),
        boardId: board.id,
        title: item.title,
        description: item.description,
        estimatedValue: item.value,
        position: i.toDouble(),
        createdAt: now,
        updatedAt: now,
      ));
      if (result case Failure(:final failure)) return Failure(failure);
    }
    return Success(board);
  }
}

/// Exclui um quadro. Os itens dele vão para "Sem quadro" por padrão, para
/// não perder o planejamento por engano; com [deleteItems] são excluídos
/// junto.
///
/// Quadro do Histórico: os itens comprados são excluídos junto (deixam de
/// contar nos relatórios) e as Pendências que saíram dele são mantidas.
class DeletePlanBoard {
  final PlanBoardRepository boardRepository;
  final PlanItemRepository itemRepository;
  const DeletePlanBoard({required this.boardRepository, required this.itemRepository});

  Future<Result<void>> call(String boardId, {bool deleteItems = false}) async {
    final itemsResult = await itemRepository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);
    final all = itemsResult.dataOrNull!;
    final boardItems = all.where((i) => i.boardId == boardId).toList();

    final boardResult = await boardRepository.getById(boardId);
    if (boardResult case Failure(:final failure)) return Failure(failure);

    if (boardResult.dataOrNull!.isFinished) {
      final purchased = boardItems.where((i) => !i.isPending).map((i) => i.id).toList();
      final pendings = boardItems.where((i) => i.isPending).toList();
      if (purchased.isNotEmpty) {
        final deleted = await itemRepository.deleteAll(purchased);
        if (deleted case Failure(:final failure)) return Failure(failure);
      }
      if (pendings.isNotEmpty) {
        final kept = await itemRepository.updateAll([for (final i in pendings) i.copyWith(clearBoard: true)]);
        if (kept case Failure(:final failure)) return Failure(failure);
      }
      return boardRepository.delete(boardId);
    }

    if (boardItems.isNotEmpty) {
      final Result<void> itemsUpdate;
      if (deleteItems) {
        itemsUpdate = await itemRepository.deleteAll(boardItems.map((i) => i.id).toList());
      } else {
        var position = PlanItemPositions.nextPosition(all, null);
        itemsUpdate = await itemRepository.updateAll([
          for (final item in boardItems) item.copyWith(clearBoard: true, position: position++),
        ]);
      }
      if (itemsUpdate case Failure(:final failure)) return Failure(failure);
    }

    return boardRepository.delete(boardId);
  }
}
