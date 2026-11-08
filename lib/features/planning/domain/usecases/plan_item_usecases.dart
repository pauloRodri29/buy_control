import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_positions.dart';

AppFailure? _validateItem({required String title, Money? value}) {
  if (!Validators.isNotBlank(title)) {
    return const ValidationFailure('Título do item é obrigatório.');
  }
  if (value != null && value.isNegative) {
    return const ValidationFailure('O valor não pode ser negativo.');
  }
  return null;
}

class GetPlanItems {
  final PlanItemRepository repository;
  const GetPlanItems(this.repository);

  Future<Result<List<PlanItemEntity>>> call() => repository.getAll();
}

class CreatePlanItem {
  final PlanItemRepository repository;
  const CreatePlanItem(this.repository);

  Future<Result<PlanItemEntity>> call({
    String? boardId,
    required String title,
    String? description,
    Money? estimatedValue,
  }) async {
    final failure = _validateItem(title: title, value: estimatedValue);
    if (failure != null) return Failure(failure);

    final itemsResult = await repository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);

    final now = DateTime.now();
    final item = PlanItemEntity(
      id: IdGenerator.generate(),
      boardId: boardId,
      title: title.trim(),
      description: Validators.isNotBlank(description) ? description!.trim() : null,
      estimatedValue: estimatedValue == null || estimatedValue.isZero ? null : estimatedValue,
      position: PlanItemPositions.nextPosition(itemsResult.dataOrNull!, boardId),
      createdAt: now,
      updatedAt: now,
    );

    final result = await repository.create(item);
    return result.fold((_) => Success(item), (f) => Failure(f));
  }
}

/// Salva a edição de um item. Se o quadro mudou, o item vai para o final
/// da coluna de destino.
class UpdatePlanItem {
  final PlanItemRepository repository;
  const UpdatePlanItem(this.repository);

  Future<Result<void>> call(PlanItemEntity item) async {
    final failure = _validateItem(title: item.title, value: item.estimatedValue);
    if (failure != null) return Failure(failure);

    final itemsResult = await repository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);
    final all = itemsResult.dataOrNull!;

    final previous = all.where((i) => i.id == item.id).firstOrNull;
    if (previous == null) return const Failure(NotFoundFailure());

    var toSave = item;
    if (previous.boardId != item.boardId) {
      final others = all.where((i) => i.id != item.id);
      toSave = item.copyWith(position: PlanItemPositions.nextPosition(others, item.boardId));
    }
    return repository.update(toSave);
  }
}

class DeletePlanItem {
  final PlanItemRepository repository;
  const DeletePlanItem(this.repository);

  Future<Result<void>> call(String id) => repository.delete(id);
}

class TogglePlanItemPurchased {
  final PlanItemRepository repository;
  const TogglePlanItemPurchased(this.repository);

  Future<Result<void>> call(PlanItemEntity item) {
    final purchased = !item.isPurchased;
    return repository.update(item.copyWith(
      isPurchased: purchased,
      purchasedAt: purchased ? DateTime.now() : null,
      clearPurchasedAt: !purchased,
    ));
  }
}

/// Move um item para outra coluna (ou reordena na mesma). Sem
/// [beforeItemId] o item vai para o final da coluna; com ele, é inserido
/// imediatamente antes desse item.
class MovePlanItem {
  final PlanItemRepository repository;
  const MovePlanItem(this.repository);

  /// Diferença mínima entre posições antes de renumerar a coluna inteira.
  static const _minGap = 1e-6;

  Future<Result<void>> call(PlanItemEntity item, {String? toBoardId, String? beforeItemId}) async {
    if (beforeItemId == item.id) return const Success(null);

    final itemsResult = await repository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);

    final siblings = PlanItemPositions.column(itemsResult.dataOrNull!.where((i) => i.id != item.id), toBoardId);
    final beforeIndex = beforeItemId == null ? -1 : siblings.indexWhere((i) => i.id == beforeItemId);

    if (beforeIndex < 0) {
      final position = siblings.isEmpty ? 0.0 : siblings.last.position + 1;
      return repository.update(_moved(item, toBoardId, position));
    }

    final next = siblings[beforeIndex].position;
    final prev = beforeIndex > 0 ? siblings[beforeIndex - 1].position : next - 1;

    if ((next - prev).abs() > _minGap) {
      return repository.update(_moved(item, toBoardId, (prev + next) / 2));
    }

    // Posições esgotadas: renumera a coluna inteira já com o item no lugar.
    final ordered = [...siblings]..insert(beforeIndex, item);
    return repository.updateAll([
      for (var i = 0; i < ordered.length; i++)
        ordered[i].id == item.id ? _moved(item, toBoardId, i.toDouble()) : ordered[i].copyWith(position: i.toDouble()),
    ]);
  }

  PlanItemEntity _moved(PlanItemEntity item, String? toBoardId, double position) {
    return item.copyWith(boardId: toBoardId, clearBoard: toBoardId == null, position: position);
  }
}
