import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/create_transaction.dart';
import 'package:buy_control/features/transactions/domain/usecases/update_transaction.dart';

/// Quantos lançamentos foram criados e quantos já existentes receberam
/// mais unidades.
class SavePurchaseResult {
  final int created;
  final int merged;
  const SavePurchaseResult({required this.created, required this.merged});
}

/// Grava uma compra nova na Box como **um lançamento por produto**: a Box
/// é uma lista de produtos, não de "rodadas" de adição.
///
/// Se o mesmo produto já estiver aberto na Box nas mesmas condições
/// (unidade, preço, desconto e sem ajustes no lançamento), soma a
/// quantidade nele em vez de criar outro card. Condições diferentes (ex.:
/// outro preço) viram um lançamento próprio, para não perder o histórico
/// de preço.
class SavePurchaseItems {
  final TransactionRepository repository;
  const SavePurchaseItems(this.repository);

  Future<Result<SavePurchaseResult>> call({
    required String boxId,
    required DateTime occurredAt,
    required List<TransactionItemEntity> items,
    String? notes,
    bool carryOver = true,
  }) async {
    if (items.isEmpty) {
      return const Failure(ValidationFailure('Adicione ao menos um produto.'));
    }

    final existingResult = await repository.getAll(boxId: boxId);
    if (existingResult.isFailure) return Failure(existingResult.failureOrNull!);
    final open = existingResult.dataOrNull!.where((t) => !t.isClosed).toList();

    final create = CreateTransaction(repository);
    final update = UpdateTransaction(repository);
    var created = 0;
    var merged = 0;

    for (final item in items) {
      final targetIndex = open.indexWhere((t) => _canMerge(t, item));

      if (targetIndex >= 0) {
        final target = open[targetIndex];
        final current = target.items.single;
        final updated = target.copyWith(
          items: [
            current
                .copyWith(
                  quantity: current.quantity + item.quantity,
                  additionalCost: current.additionalCost + item.additionalCost,
                )
                .withRecalculatedDiscount(),
          ],
          carryOver: carryOver,
          updatedAt: DateTime.now(),
        );
        final result = await update(updated);
        if (result.isFailure) return Failure(result.failureOrNull!);
        open[targetIndex] = updated;
        merged++;
      } else {
        final result = await create(
          boxId: boxId,
          occurredAt: occurredAt,
          notes: notes,
          items: [item],
          carryOver: carryOver,
        );
        if (result.isFailure) return Failure(result.failureOrNull!);
        open.add(result.dataOrNull!);
        created++;
      }
    }

    return Success(SavePurchaseResult(created: created, merged: merged));
  }

  static bool _canMerge(TransactionEntity transaction, TransactionItemEntity item) {
    if (item.productId == null) return false;
    if (transaction.items.length != 1) return false;
    if (!transaction.discount.isZero || !transaction.additionalCost.isZero) return false;

    final current = transaction.items.single;
    if (current.productId != item.productId) return false;
    if (current.unitId != item.unitId) return false;
    if (current.unitPrice != item.unitPrice) return false;
    if (current.discountRule != item.discountRule) return false;
    // Desconto digitado à mão (sem regra) não dá para recalcular ao somar.
    if (current.discountRule == null && (!current.discount.isZero || !item.discount.isZero)) return false;
    return true;
  }
}
