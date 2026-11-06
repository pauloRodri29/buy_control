import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/create_transaction.dart';
import 'package:buy_control/features/transactions/domain/usecases/update_transaction.dart';
import 'package:buy_control/features/transactions/presentation/purchase_draft.dart';
import 'package:buy_control/features/transactions/presentation/widgets/carry_over_switch.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Como o resumo foi fechado: compra gravada, ou o usuário quer voltar ao
/// editor de itens (o rascunho continua intacto).
enum PurchaseSummaryResult { confirmed, editItems }

/// Último passo do fluxo de compra: nada foi salvo até aqui — só ao tocar
/// em "Confirmar" é que o lançamento é criado ([CreateTransaction]) ou
/// atualizado ([UpdateTransaction], quando o rascunho veio de um
/// lançamento aberto). Tocar num item volta para o editor.
class PurchaseSummaryStep extends StatefulWidget {
  final PurchaseDraft draft;
  final String boxName;

  const PurchaseSummaryStep({super.key, required this.draft, required this.boxName});

  @override
  State<PurchaseSummaryStep> createState() => _PurchaseSummaryStepState();
}

class _PurchaseSummaryStepState extends State<PurchaseSummaryStep> {
  PurchaseDraft get _draft => widget.draft;
  bool _submitting = false;
  String? _errorMessage;

  void _editItems() => Navigator.of(context).pop(PurchaseSummaryResult.editItems);

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repository = Get.find<TransactionRepository>();
    final original = _draft.original;
    final Result<void> result;
    if (original == null) {
      result = await CreateTransaction(repository)(
        boxId: _draft.boxId,
        title: _draft.title,
        occurredAt: _draft.occurredAt,
        notes: _draft.notes,
        discount: _draft.discount,
        additionalCost: _draft.additionalCost,
        items: _draft.items,
        carryOver: _draft.carryOver,
      );
    } else {
      result = await UpdateTransaction(repository)(original.copyWith(
        title: _draft.title,
        occurredAt: _draft.occurredAt,
        notes: _draft.notes,
        // Observação apagada no editor precisa sumir também do lançamento.
        clearNotes: _draft.notes == null,
        carryOver: _draft.carryOver,
        discount: _draft.discount,
        additionalCost: _draft.additionalCost,
        items: _draft.items.map((i) => i.copyWith(transactionId: original.id)).toList(),
        updatedAt: DateTime.now(),
      ));
    }

    if (!mounted) return;
    result.fold((_) {
      Navigator.of(context).pop(PurchaseSummaryResult.confirmed);
    }, (failure) {
      setState(() {
        _submitting = false;
        _errorMessage = FailurePresenter.present(failure);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppText.title('Resumo da compra', fontSize: AppFontSizes.fz09)),
              AppButton.text(
                label: 'Editar itens',
                icon: LucideIcons.pencil,
                onPressed: _submitting ? null : _editItems,
              ),
            ],
          ),
          AppText.subtitle('${widget.boxName} · ${DateTimeFormatter.ddMMyyyy(_draft.occurredAt)}'),
          const SizedBox(height: AppSpacing.lg),
          ..._draft.items.map((item) => InkWell(
                onTap: _submitting ? null : _editItems,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(item.nameSnapshot, fontWeight: FontWeight.w600),
                            AppText.subtitle('${QuantityFormatter.format(item.quantity)} × ${item.unitPrice.formatted}'),
                            if (!item.discount.isZero)
                              AppText(
                                '${item.discountRule?.description ?? 'Desconto'} · - ${item.discount.formatted}',
                                color: AppColors.accent,
                                fontSize: AppFontSizes.fz06,
                              ),
                          ],
                        ),
                      ),
                      AppText(item.total.formatted, fontWeight: FontWeight.w600),
                    ],
                  ),
                ),
              )),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: AppMoneyField(
                  initialValue: _draft.discount,
                  label: 'Desconto na compra (opcional)',
                  onChanged: (money) => setState(() => _draft.discount = money),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppMoneyField(
                  initialValue: _draft.additionalCost,
                  label: 'Acréscimo (opcional)',
                  onChanged: (money) => setState(() => _draft.additionalCost = money),
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
                _draft.total.formatted,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontSize: AppFontSizes.fz09,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CarryOverSwitch(value: _draft.carryOver, onChanged: (v) => setState(() => _draft.carryOver = v)),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(_errorMessage!, color: AppColors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _draft.isEditing ? 'Salvar alterações' : 'Confirmar',
            onPressed: _submitting ? null : _confirm,
          ),
          const SizedBox(height: AppSpacing.xs),
          const AppText.subtitle('Toque num item para alterar quantidade, preço ou desconto.'),
        ],
      ),
    );
  }
}
