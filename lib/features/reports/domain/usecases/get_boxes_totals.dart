import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class BoxTotal {
  final String boxId;
  final String boxName;
  final Money total;
  final int transactionCount;
  const BoxTotal({
    required this.boxId,
    required this.boxName,
    required this.total,
    required this.transactionCount,
  });
}

/// Totais de todas as Boxes (histórico completo), base para o módulo de
/// Relatórios combinar Boxes selecionadas pelo usuário.
class GetBoxesTotals {
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;

  const GetBoxesTotals({required this.boxRepository, required this.transactionRepository});

  Future<Result<List<BoxTotal>>> call() async {
    final boxesResult = await boxRepository.getAll();
    if (boxesResult.isFailure) return Failure(boxesResult.failureOrNull!);

    final transactionsResult = await transactionRepository.getAll();
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    final transactions = transactionsResult.dataOrNull!;

    final totals = boxesResult.dataOrNull!.map((box) {
      final boxTransactions = transactions.where((t) => t.boxId == box.id);
      final total = boxTransactions.fold(Money.zero, (sum, t) => sum + t.total);
      return BoxTotal(
        boxId: box.id,
        boxName: box.name,
        total: total,
        transactionCount: boxTransactions.length,
      );
    }).toList()
      ..sort((a, b) => b.total.cents.compareTo(a.total.cents));

    return Success(totals);
  }
}
