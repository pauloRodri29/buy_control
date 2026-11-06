import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/presentation/pages/product_picker_sheet.dart';
import 'package:buy_control/features/transactions/presentation/purchase_draft.dart';
import 'package:buy_control/features/transactions/presentation/scan_items_flow.dart';
import 'package:buy_control/features/transactions/presentation/widgets/discount_rule_editor.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Editor dos itens de uma compra (nova ou já lançada e ainda aberta).
/// Trabalha direto sobre o [PurchaseDraft]: altera quantidade, preço,
/// unidade, promoção e acréscimo de cada item e remove itens. Só numa
/// compra nova dá para adicionar produtos (catálogo ou leitor); na edição
/// de um lançamento, apenas os itens já lançados são alterados. Fecha com
/// `true` em "Continuar"; nada é gravado aqui.
class ItemDetailsStep extends StatefulWidget {
  final PurchaseDraft draft;
  const ItemDetailsStep({super.key, required this.draft});

  @override
  State<ItemDetailsStep> createState() => _ItemDetailsStepState();
}

class _ItemDetailsStepState extends State<ItemDetailsStep> {
  PurchaseDraft get _draft => widget.draft;

  late final _notesController = TextEditingController(text: _draft.notes ?? '');
  List<UnitEntity> _units = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final result = await Get.find<GetUnits>()(includeInactive: true);
    result.fold((data) {
      if (!mounted) return;
      setState(() => _units = data);
    }, (_) {});
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addProducts() async {
    final selected = await AppBottomSheet.show<List<ProductEntity>>(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: const ProductPickerSheet(),
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    setState(() {
      _draft.addProducts(selected);
      _errorMessage = null;
    });
  }

  Future<void> _scanProducts() async {
    await scanIntoDraft(context, _draft);
    if (!mounted) return;
    setState(() => _errorMessage = null);
  }

  void _updateItem(int index, TransactionItemEntity item) {
    setState(() => _draft.items[index] = item.withRecalculatedDiscount());
  }

  void _removeItem(int index) {
    setState(() => _draft.items.removeAt(index));
  }

  void _continue() {
    if (_draft.items.isEmpty) {
      setState(() => _errorMessage = 'Adicione ao menos um produto.');
      return;
    }
    for (final item in _draft.items) {
      if (item.quantity <= 0) {
        setState(() => _errorMessage = 'Quantidade inválida para "${item.nameSnapshot}".');
        return;
      }
    }
    final notes = _notesController.text.trim();
    _draft.notes = notes.isEmpty ? null : notes;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.title(_draft.isEditing ? 'Editar itens' : 'Detalhes dos itens', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView(
            children: [
              AppTextField(controller: _notesController, label: 'Observação (opcional)', maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < _draft.items.length; i++) ...[
                _ItemForm(
                  key: ValueKey(_draft.items[i].id),
                  item: _draft.items[i],
                  units: _units,
                  onChanged: (item) => _updateItem(i, item),
                  // Na edição não dá para esvaziar a compra: só remove se sobrar algum item.
                  onRemove: _draft.isEditing && _draft.items.length <= 1 ? null : () => _removeItem(i),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Editar um lançamento altera só os itens já lançados.
              if (!_draft.isEditing)
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Adicionar produto',
                        icon: LucideIcons.plus,
                        onPressed: _addProducts,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Escanear',
                        icon: LucideIcons.scanBarcode,
                        onPressed: _scanProducts,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppText(_errorMessage!, color: AppColors.error),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText('${_draft.items.length} itens', color: AppColors.textSecondary(isDark)),
            AppText(_draft.itemsTotal.formatted, fontWeight: FontWeight.bold, color: AppColors.accent),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Continuar', onPressed: _continue),
      ],
    );
  }
}

class _ItemForm extends StatefulWidget {
  final TransactionItemEntity item;
  final List<UnitEntity> units;
  final ValueChanged<TransactionItemEntity> onChanged;
  final VoidCallback? onRemove;

  const _ItemForm({
    super.key,
    required this.item,
    required this.units,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  late final _quantityController = TextEditingController(text: QuantityFormatter.format(widget.item.quantity));


  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityTyped(String text) {
    final quantity = QuantityFormatter.parse(text) ?? 0;
    widget.onChanged(widget.item.copyWith(quantity: quantity));
  }

  void _step(int delta) {
    final next = widget.item.quantity + delta;
    if (next < 1) return;
    _quantityController.text = QuantityFormatter.format(next);
    widget.onChanged(widget.item.copyWith(quantity: next));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;
    final unitOptions =
        widget.units.map((u) => AppDropdownOption(value: u.id, label: '${u.name} (${u.abbreviation})')).toList();
    final hasUnit = unitOptions.any((o) => o.value == item.unitId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(isDark),
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppText(item.nameSnapshot, fontWeight: FontWeight.w600)),
              if (widget.onRemove != null)
                IconButton(
                  tooltip: 'Remover item',
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                tooltip: 'Diminuir',
                icon: const Icon(LucideIcons.minus, size: 16),
                onPressed: item.quantity > 1 ? () => _step(-1) : null,
              ),
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'Quantidade',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onQuantityTyped,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Aumentar',
                icon: const Icon(LucideIcons.plus, size: 16),
                onPressed: () => _step(1),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppMoneyField(
                  initialValue: item.unitPrice,
                  label: 'Preço unitário',
                  onChanged: (money) => widget.onChanged(widget.item.copyWith(unitPrice: money)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<String>(
            label: 'Unidade',
            hint: 'Selecione',
            value: hasUnit ? item.unitId : null,
            options: unitOptions,
            onChanged: (value) {
              if (value != null) widget.onChanged(widget.item.copyWith(unitId: value));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DiscountRuleEditor(
            initialRule: item.discountRule,
            onChanged: (rule) => widget.onChanged(
              rule == null
                  ? widget.item.copyWith(clearDiscountRule: true, discount: Money.zero)
                  : widget.item.copyWith(discountRule: rule),
            ),
          ),
          if (item.discountRule == null && !item.discount.isZero) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText.subtitle('Desconto lançado anteriormente: ${item.discount.formatted}'),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppMoneyField(
            initialValue: item.additionalCost,
            label: 'Acréscimo (opcional)',
            onChanged: (money) => widget.onChanged(widget.item.copyWith(additionalCost: money)),
          ),
          const Divider(height: AppSpacing.lg),
          if (!item.discount.isZero)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText.subtitle('Você economiza'),
                AppText('- ${item.discount.formatted}', color: AppColors.accent, fontWeight: FontWeight.w600),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText.subtitle('Total do item'),
              AppText(item.total.formatted, fontWeight: FontWeight.w600),
            ],
          ),
        ],
      ),
    );
  }
}
