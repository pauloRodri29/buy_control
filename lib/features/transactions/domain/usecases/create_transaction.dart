import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class CreateTransaction {
  final TransactionRepository repository;
  const CreateTransaction(this.repository);

  Future<Result<TransactionEntity>> call({
    required String boxId,
    String? title,
    required DateTime occurredAt,
    String? description,
    String? notes,
    Money discount = Money.zero,
    Money additionalCost = Money.zero,
    required List<TransactionItemEntity> items,
    bool carryOver = true,
  }) async {
    if (!Validators.isNotBlank(boxId)) {
      return const Failure(ValidationFailure('Box é obrigatória.'));
    }
    if (items.isEmpty) {
      return const Failure(
        ValidationFailure('Informe ao menos um item ou lançamento avulso.'),
      );
    }
    for (final item in items) {
      if (!Validators.isPositive(item.quantity)) {
        return Failure(
          ValidationFailure('Quantidade inválida para "${item.nameSnapshot}".'),
        );
      }
      if (item.unitPrice.cents < 0) {
        return Failure(
          ValidationFailure('Preço unitário inválido para "${item.nameSnapshot}".'),
        );
      }
    }

    final now = DateTime.now();
    final id = IdGenerator.generate();
    final draft = TransactionEntity(
      id: id,
      boxId: boxId.trim(),
      title: title?.trim(),
      occurredAt: occurredAt,
      description: _blankToNull(description),
      notes: _blankToNull(notes),
      discount: discount,
      additionalCost: additionalCost,
      items: items.map((item) => item.copyWith(transactionId: id)).toList(),
      carryOver: carryOver,
      createdAt: now,
      updatedAt: now,
    );

    // O total nunca pode ficar negativo: desconto maior que o valor dos
    // itens indicaria um lançamento inconsistente.
    if (draft.total.isNegative) {
      return const Failure(
        ValidationFailure('O desconto não pode tornar o total negativo.'),
      );
    }

    final result = await repository.create(draft);
    return result.fold((_) => Success(draft), (f) => Failure(f));
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
