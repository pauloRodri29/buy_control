import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

/// Congela os lançamentos abertos de uma Box num snapshot imutável
/// (Fechamento). Depois disso, a Box continua existindo e pode receber
/// novos lançamentos normalmente — eles começam um novo ciclo aberto.
class CloseBox {
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;
  final BoxClosureRepository closureRepository;

  const CloseBox({
    required this.boxRepository,
    required this.transactionRepository,
    required this.closureRepository,
  });

  Future<Result<BoxClosureEntity>> call({required String boxId, String? notes}) async {
    final boxResult = await boxRepository.getById(boxId);
    if (boxResult.isFailure) return Failure(boxResult.failureOrNull!);
    final box = boxResult.dataOrNull!;

    final transactionsResult = await transactionRepository.getAll(boxId: boxId);
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    final openTransactions = transactionsResult.dataOrNull!.where((t) => !t.isClosed).toList();
    if (openTransactions.isEmpty) {
      return const Failure(ValidationFailure('Esta Box não tem lançamentos abertos para fechar.'));
    }

    final now = DateTime.now();
    final closure = BoxClosureEntity(
      id: IdGenerator.generate(),
      boxId: boxId,
      boxNameSnapshot: box.name,
      closedAt: now,
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      total: openTransactions.fold(Money.zero, (sum, t) => sum + t.total),
      transactionCount: openTransactions.length,
      itemCount: openTransactions.fold(0, (sum, t) => sum + t.itemCount),
      createdAt: now,
      updatedAt: now,
    );

    final createResult = await closureRepository.create(closure);
    if (createResult.isFailure) return Failure(createResult.failureOrNull!);

    for (final transaction in openTransactions) {
      await transactionRepository.update(transaction.copyWith(closureId: closure.id, updatedAt: now));
    }

    return Success(closure);
  }
}
