import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_positions.dart';

AppFailure? _validateBoard({required String title, Money? goal}) {
  if (!Validators.isNotBlank(title)) {
    return const ValidationFailure('Título do quadro é obrigatório.');
  }
  if (goal != null && goal.isNegative) {
    return const ValidationFailure('A meta não pode ser negativa.');
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
  const CreatePlanBoard(this.repository);

  Future<Result<PlanBoardEntity>> call({
    required String title,
    String? description,
    Money? goal,
    required DateTime targetDate,
  }) async {
    final failure = _validateBoard(title: title, goal: goal);
    if (failure != null) return Failure(failure);

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

/// Fecha um quadro: todos os itens ainda pendentes são marcados como
/// comprados em [purchasedAt] (é essa data que define em que mês a compra
/// entra nos relatórios). Itens já comprados mantêm a data original.
class ClosePlanBoard {
  final PlanBoardRepository boardRepository;
  final PlanItemRepository itemRepository;
  const ClosePlanBoard({required this.boardRepository, required this.itemRepository});

  Future<Result<void>> call(PlanBoardEntity board, {required DateTime purchasedAt}) async {
    if (board.isClosed) return const Failure(ValidationFailure('Este quadro já está fechado.'));

    final itemsResult = await itemRepository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);

    final pending = itemsResult.dataOrNull!.where((i) => i.boardId == board.id && !i.isPurchased).toList();
    if (pending.isNotEmpty) {
      final itemsUpdate = await itemRepository.updateAll([
        for (final item in pending) item.copyWith(isPurchased: true, purchasedAt: purchasedAt),
      ]);
      if (itemsUpdate case Failure(:final failure)) return Failure(failure);
    }

    return boardRepository.update(board.copyWith(closedAt: purchasedAt));
  }
}

/// Reabre um quadro fechado. Os itens continuam marcados como comprados;
/// o usuário desmarca individualmente o que não foi comprado de fato.
class ReopenPlanBoard {
  final PlanBoardRepository repository;
  const ReopenPlanBoard(this.repository);

  Future<Result<void>> call(PlanBoardEntity board) {
    return repository.update(board.copyWith(clearClosedAt: true));
  }
}

/// Exclui um quadro. Os itens dele vão para "Sem quadro" por padrão, para
/// não perder o planejamento por engano; com [deleteItems] são excluídos
/// junto.
class DeletePlanBoard {
  final PlanBoardRepository boardRepository;
  final PlanItemRepository itemRepository;
  const DeletePlanBoard({required this.boardRepository, required this.itemRepository});

  Future<Result<void>> call(String boardId, {bool deleteItems = false}) async {
    final itemsResult = await itemRepository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);
    final all = itemsResult.dataOrNull!;
    final boardItems = all.where((i) => i.boardId == boardId).toList();

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
