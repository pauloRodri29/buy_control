import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

/// Fecha o ciclo de compras de uma Box numa data de referência escolhida
/// pelo usuário (ex.: as compras do mês). O Fechamento é definitivo:
///
/// 1. Os lançamentos abertos são congelados no Fechamento (viram registro
///    para balanço e relatórios, sem edição nem reabertura).
/// 2. Os lançamentos marcados como "Repetir no próximo ciclo" (padrão)
///    voltam para a Box: os mesmos itens — mesma quantidade, preço e
///    promoção — são copiados como novos lançamentos abertos, prontos para
///    o próximo ciclo. O usuário só ajusta o que mudou.
///
/// Tudo ou nada: se qualquer gravação falhar, o que já foi gravado é
/// desfeito e a Box volta exatamente ao estado anterior.
class CloseBox {
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;
  final BoxClosureRepository closureRepository;

  const CloseBox({
    required this.boxRepository,
    required this.transactionRepository,
    required this.closureRepository,
  });

  Future<Result<BoxClosureEntity>> call({
    required String boxId,
    required DateTime referenceDate,
    String? notes,
  }) async {
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
    final reference = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final trimmedNotes = notes?.trim();
    final closure = BoxClosureEntity(
      id: IdGenerator.generate(),
      boxId: boxId,
      boxNameSnapshot: box.name,
      referenceDate: reference,
      closedAt: now,
      notes: trimmedNotes == null || trimmedNotes.isEmpty ? null : trimmedNotes,
      total: openTransactions.fold(Money.zero, (sum, t) => sum + t.total),
      transactionCount: openTransactions.length,
      itemCount: openTransactions.fold(0, (sum, t) => sum + t.itemCount),
      createdAt: now,
      updatedAt: now,
    );

    final closedOriginals = <TransactionEntity>[];
    final createdCopies = <String>[];
    var closureCreated = false;

    Future<Result<BoxClosureEntity>> rollback(AppFailure failure) async {
      for (final id in createdCopies) {
        await transactionRepository.delete(id);
      }
      for (final original in closedOriginals) {
        await transactionRepository.update(original);
      }
      if (closureCreated) await closureRepository.delete(closure.id);
      return Failure(failure);
    }

    final createResult = await closureRepository.create(closure);
    if (createResult.isFailure) return Failure(createResult.failureOrNull!);
    closureCreated = true;

    for (final transaction in openTransactions) {
      final frozen = transaction.copyWith(
        closureId: closure.id,
        closureReferenceDate: reference,
        updatedAt: now,
      );
      final updateResult = await transactionRepository.update(frozen);
      if (updateResult.isFailure) return rollback(updateResult.failureOrNull!);
      closedOriginals.add(transaction);
    }

    // Só volta para a Box o que o usuário marcou como "Repetir no próximo
    // ciclo"; o resto fica apenas no histórico do Fechamento.
    for (final transaction in openTransactions.where((t) => t.carryOver)) {
      final copy = _copyForNextCycle(transaction, now);
      final copyResult = await transactionRepository.create(copy);
      if (copyResult.isFailure) return rollback(copyResult.failureOrNull!);
      createdCopies.add(copy.id);
    }

    return Success(closure);
  }

  /// Novo lançamento aberto idêntico ao [original] (itens, quantidades,
  /// preços, promoções, desconto/acréscimo gerais), com ids novos e data
  /// de hoje.
  TransactionEntity _copyForNextCycle(TransactionEntity original, DateTime now) {
    final id = IdGenerator.generate();
    return TransactionEntity(
      id: id,
      boxId: original.boxId,
      title: original.title,
      occurredAt: now,
      description: original.description,
      notes: original.notes,
      discount: original.discount,
      additionalCost: original.additionalCost,
      carryOver: original.carryOver,
      items: original.items.map((item) => item.copyWith(id: IdGenerator.generate(), transactionId: id)).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
