import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/create_transaction.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Último passo do fluxo de compra: nada foi salvo até aqui — só ao tocar
/// em "Confirmar" é que [CreateTransaction] grava o lançamento. Fechar ou
/// voltar antes disso não deixa nenhum rastro.
class PurchaseSummaryStep extends StatefulWidget {
  final String boxId;
  final String boxName;
  final List<TransactionItemEntity> items;
  final DateTime occurredAt;
  final String? notes;
  final String? title;

  const PurchaseSummaryStep({
    super.key,
    required this.boxId,
    required this.boxName,
    required this.items,
    required this.occurredAt,
    this.notes,
    this.title,
  });

  @override
  State<PurchaseSummaryStep> createState() => _PurchaseSummaryStepState();
}

class _PurchaseSummaryStepState extends State<PurchaseSummaryStep> {
  final _discountController = TextEditingController();
  final _additionalCostController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _discountController.dispose();
    _additionalCostController.dispose();
    super.dispose();
  }

  Money _parseMoney(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return Money.zero;
    final value = double.tryParse(trimmed.replaceAll(',', '.'));
    return value == null ? Money.zero : Money.fromReais(value);
  }

  TransactionEntity get _draft {
    final now = DateTime.now();
    return TransactionEntity(
      id: '',
      boxId: widget.boxId,
      title: widget.title,
      occurredAt: widget.occurredAt,
      notes: widget.notes,
      discount: _parseMoney(_discountController.text),
      additionalCost: _parseMoney(_additionalCostController.text),
      items: widget.items,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final draft = _draft;
    final createTransaction = CreateTransaction(Get.find<TransactionRepository>());
    final result = await createTransaction(
      boxId: draft.boxId,
      title: draft.title,
      occurredAt: draft.occurredAt,
      notes: draft.notes,
      discount: draft.discount,
      additionalCost: draft.additionalCost,
      items: draft.items,
    );

    if (!mounted) return;
    result.fold((_) {
      Navigator.of(context).pop(true);
    }, (failure) {
      setState(() {
        _submitting = false;
        _errorMessage = FailurePresenter.present(failure);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title('Resumo da compra', fontSize: AppFontSizes.fz09),
          const SizedBox(height: AppSpacing.xs),
          AppText.subtitle('${widget.boxName} · ${DateTimeFormatter.ddMMyyyy(widget.occurredAt)}'),
          const SizedBox(height: AppSpacing.lg),
          ...widget.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(item.nameSnapshot, fontWeight: FontWeight.w600),
                          AppText.subtitle('${item.quantity} × ${item.unitPrice.formatted}'),
                        ],
                      ),
                    ),
                    AppText(item.total.formatted, fontWeight: FontWeight.w600),
                  ],
                ),
              )),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _discountController,
                  label: 'Desconto (opcional)',
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _additionalCostController,
                  label: 'Acréscimo (opcional)',
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText('Total', fontWeight: FontWeight.bold),
              AppText(
                draft.total.formatted,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontSize: AppFontSizes.fz09,
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(_errorMessage!, color: AppColors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Confirmar', onPressed: _submitting ? null : _confirm),
        ],
      ),
    );
  }
}
