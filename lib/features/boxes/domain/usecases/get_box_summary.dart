import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class BoxSummary {
  final Money total;
  final int transactionCount;
  final int itemCount;
  final DateTime? lastMovementAt;

  const BoxSummary({
    required this.total,
    required this.transactionCount,
    required this.itemCount,
    this.lastMovementAt,
  });
}

class GetBoxSummary {
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;

  const GetBoxSummary({required this.boxRepository, required this.transactionRepository});

  Future<Result<BoxSummary>> call(String boxId) async {
    final boxResult = await boxRepository.getById(boxId);
    if (boxResult.isFailure) return Failure(boxResult.failureOrNull!);

    final transactionsResult = await transactionRepository.getAll(boxId: boxId);
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    // Resumo do ciclo atual (aberto). O que já foi fechado fica no
    // histórico de Fechamentos — somar aqui duplicaria os itens, já que o
    // fechamento copia os produtos para o novo ciclo.
    final transactions = transactionsResult.dataOrNull!.where((t) => !t.isClosed).toList();
    final total = transactions.fold(Money.zero, (sum, t) => sum + t.total);
    final itemCount = transactions.fold(0, (sum, t) => sum + t.itemCount);
    final lastMovementAt = transactions.isEmpty
        ? null
        : transactions.map((t) => t.occurredAt).reduce((a, b) => a.isAfter(b) ? a : b);

    return Success(BoxSummary(
      total: total,
      transactionCount: transactions.length,
      itemCount: itemCount,
      lastMovementAt: lastMovementAt,
    ));
  }
}
