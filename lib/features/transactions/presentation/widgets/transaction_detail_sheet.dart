import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mostra os detalhes completos de um lançamento: itens, quantidades,
/// preços unitários e o cálculo final (subtotal, desconto, acréscimo,
/// total) — sempre lido dos getters da entidade, nunca recalculado aqui.
class TransactionDetailSheet extends StatefulWidget {
  final TransactionEntity transaction;
  const TransactionDetailSheet({super.key, required this.transaction});

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  Map<String, UnitEntity> _unitsById = {};

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final result = await Get.find<GetUnits>()(includeInactive: true);
    result.fold((units) {
      if (!mounted) return;
      setState(() => _unitsById = {for (final u in units) u.id: u});
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transaction = widget.transaction;
    final title = (transaction.title != null && transaction.title!.trim().isNotEmpty)
        ? transaction.title!
        : (transaction.items.isNotEmpty ? transaction.items.first.nameSnapshot : 'Lançamento');

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title(title, fontSize: AppFontSizes.fz09),
          const SizedBox(height: AppSpacing.xs),
          AppText.subtitle(DateTimeFormatter.ddMMyyyyHHmm(transaction.occurredAt)),
          if (transaction.description != null && transaction.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(transaction.description!),
          ],
          if (transaction.notes != null && transaction.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(transaction.notes!, color: AppColors.textSecondary(isDark)),
          ],
          const SizedBox(height: AppSpacing.lg),
          ...transaction.items.map((item) {
            final unit = _unitsById[item.unitId];
            final quantity = QuantityFormatter.format(item.quantity);
            final quantityLabel = unit != null ? '$quantity ${unit.abbreviation}' : quantity;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(item.nameSnapshot, fontWeight: FontWeight.w600),
                        AppText.subtitle('$quantityLabel × ${item.unitPrice.formatted}'),
                      ],
                    ),
                  ),
                  AppText(item.total.formatted, fontWeight: FontWeight.w600),
                ],
              ),
            );
          }),
          const Divider(),
          _SummaryRow(label: 'Subtotal', value: transaction.itemsTotal.formatted),
          if (!transaction.discount.isZero)
            _SummaryRow(label: 'Desconto', value: '- ${transaction.discount.formatted}'),
          if (!transaction.additionalCost.isZero)
            _SummaryRow(label: 'Acréscimo', value: '+ ${transaction.additionalCost.formatted}'),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(label: 'Total', value: transaction.total.formatted, emphasize: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _SummaryRow({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            color: emphasize ? null : AppColors.textSecondary(isDark),
          ),
          AppText(
            value,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
            color: emphasize ? AppColors.accent : null,
          ),
        ],
      ),
    );
  }
}
