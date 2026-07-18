import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class BoxClosureDetails {
  final BoxClosureEntity closure;
  final List<TransactionEntity> transactions;
  const BoxClosureDetails({required this.closure, required this.transactions});
}

/// Detalhe de um Fechamento: o cabeçalho congelado mais os lançamentos
/// que ficaram presos a ele. Como esses lançamentos nunca mais mudam
/// (guarda de imutabilidade em `UpdateTransaction`/`DeleteTransaction`),
/// esta consulta sempre reflete exatamente o que existia no momento do
/// fechamento — sem precisar duplicar os dados na própria entidade.
class GetBoxClosureDetails {
  final BoxClosureRepository closureRepository;
  final TransactionRepository transactionRepository;

  const GetBoxClosureDetails({required this.closureRepository, required this.transactionRepository});

  Future<Result<BoxClosureDetails>> call(String closureId) async {
    final closureResult = await closureRepository.getById(closureId);
    if (closureResult.isFailure) return Failure(closureResult.failureOrNull!);
    final closure = closureResult.dataOrNull!;

    final transactionsResult = await transactionRepository.getAll(boxId: closure.boxId);
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    final transactions = transactionsResult.dataOrNull!.where((t) => t.closureId == closureId).toList();
    return Success(BoxClosureDetails(closure: closure, transactions: transactions));
  }
}
