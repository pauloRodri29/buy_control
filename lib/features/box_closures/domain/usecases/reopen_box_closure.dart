import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

/// Desfaz um Fechamento feito por engano: os lançamentos voltam a ficar
/// abertos (editáveis) e o Fechamento é removido (exclusão lógica).
class ReopenBoxClosure {
  final BoxClosureRepository closureRepository;
  final TransactionRepository transactionRepository;

  const ReopenBoxClosure({required this.closureRepository, required this.transactionRepository});

  Future<Result<void>> call(String closureId) async {
    final closureResult = await closureRepository.getById(closureId);
    if (closureResult.isFailure) return Failure(closureResult.failureOrNull!);
    final closure = closureResult.dataOrNull!;

    final transactionsResult = await transactionRepository.getAll(boxId: closure.boxId);
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    final now = DateTime.now();
    final linked = transactionsResult.dataOrNull!.where((t) => t.closureId == closureId);
    for (final transaction in linked) {
      await transactionRepository.update(transaction.copyWith(clearClosureId: true, updatedAt: now));
    }

    return closureRepository.update(closure.copyWith(deletedAt: now, updatedAt: now));
  }
}
