import 'package:buy_control/app/theme/theme_context.dart';
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
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/presentation/plan_features.dart';

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

  /// Produto aberto para edição (acordeão: um por vez). Com um só
  /// produto ele já vem aberto; com vários, todos começam recolhidos.
  late String? _expandedId = _draft.items.length == 1 ? _draft.items.first.id : null;

  /// Depois de adicionar produtos, abre o último que entrou na lista.
  void _expandLastAddedSince(int previousCount) {
    if (_draft.items.length > previousCount) _expandedId = _draft.items.last.id;
  }

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
    final previousCount = _draft.items.length;
    setState(() {
      _draft.addProducts(selected);
      _expandLastAddedSince(previousCount);
      _errorMessage = null;
    });
  }

  Future<void> _scanProducts() async {
    final previousCount = _draft.items.length;
    await scanIntoDraft(context, _draft);
    if (!mounted) return;
    setState(() {
      _expandLastAddedSince(previousCount);
      _errorMessage = null;
    });
  }

  void _updateItem(int index, TransactionItemEntity item) {
    setState(() => _draft.items[index] = item.withRecalculatedDiscount());
  }

  void _removeItem(int index) {
    setState(() => _draft.items.removeAt(index));
  }

  void _continue() {
    if (_draft.items.isEmpty) {
      setState(() => _errorMessage = 'transactions.addLeastOneProduct'.tr);
      return;
    }
    for (final item in _draft.items) {
      if (item.quantity <= 0) {
        setState(() => _errorMessage = 'transactions.invalidQuantityNameSnapshot'.trParams({'nameSnapshot': item.nameSnapshot}));
        return;
      }
    }
    final notes = _notesController.text.trim();
    _draft.notes = notes.isEmpty ? null : notes;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading(_draft.isEditing ? 'transactions.editItems'.tr : 'transactions.itemDetails'.tr),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView(
            children: [
              AppTextField(controller: _notesController, label: 'transactions.noteOptional'.tr, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < _draft.items.length; i++) ...[
                _ItemForm(
                  key: ValueKey(_draft.items[i].id),
                  item: _draft.items[i],
                  units: _units,
                  expanded: _draft.items[i].id == _expandedId,
                  onExpansionChanged: (open) {
                    final id = _draft.items[i].id;
                    setState(() => _expandedId = open ? id : (_expandedId == id ? null : _expandedId));
                  },
                  onChanged: (item) => _updateItem(i, item),
                  // Na edição não dá para esvaziar a compra: só remove se sobrar algum item.
                  onRemove: _draft.isEditing && _draft.items.length <= 1 ? null : () => _removeItem(i),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.xs),
              // Editar um lançamento altera só os itens já lançados.
              if (!_draft.isEditing)
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(label: 'common.product'.tr, icon: Symbols.add, onPressed: _addProducts),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.secondary(
                        label: 'transactions.scan'.tr,
                        icon: Symbols.qr_code_scanner,
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
          AppText(_errorMessage!, color: context.colors.error),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              _draft.items.length == 1 ? 'transactions.n1Product'.tr : 'transactions.productsCount'.trParams({'length': '${_draft.items.length}'}),
              color: context.colors.onSurfaceVariant,
            ),
            AppText(_draft.itemsTotal.formatted, fontWeight: FontWeight.bold, color: context.colors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'common.continue'.tr, onPressed: _continue),
      ],
    );
  }
}

/// Um produto da compra como card recolhível ([ExpansionTile] nativo).
/// Fechado mostra o resumo (nome, quantidade × preço, desconto, total);
/// aberto mostra o formulário completo do item.
class _ItemForm extends StatefulWidget {
  final TransactionItemEntity item;
  final List<UnitEntity> units;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<TransactionItemEntity> onChanged;
  final VoidCallback? onRemove;

  const _ItemForm({
    super.key,
    required this.item,
    required this.units,
    required this.expanded,
    required this.onExpansionChanged,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  late final _quantityController = TextEditingController(text: QuantityFormatter.format(widget.item.quantity));
  final _expansion = ExpansibleController();

  @override
  void didUpdateWidget(covariant _ItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Acordeão: o pai decide qual card fica aberto.
    if (widget.expanded != oldWidget.expanded && widget.expanded != _expansion.isExpanded) {
      widget.expanded ? _expansion.expand() : _expansion.collapse();
    }
  }

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

  String get _summary {
    final item = widget.item;
    final base = '${QuantityFormatter.format(item.quantity)} × ${item.unitPrice.formatted}';
    if (item.discount.isZero) return base;
    return '$base · ${item.discountRule?.description ?? 'desconto'} (- ${item.discount.formatted})';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final text = context.text;
    final unitOptions = widget.units
        .map((u) => AppDropdownOption(value: u.id, label: '${u.name} (${u.abbreviation})'))
        .toList();
    final hasUnit = unitOptions.any((o) => o.value == item.unitId);

    return Card.filled(
      margin: EdgeInsets.zero,
      color: context.colors.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        controller: _expansion,
        initiallyExpanded: widget.expanded,
        onExpansionChanged: widget.onExpansionChanged,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.nameSnapshot,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(item.total.formatted, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        subtitle: Text(
          _summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: item.discount.isZero ? null : context.colors.primary),
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                tooltip: 'common.decrease'.tr,
                icon: const Icon(Symbols.remove, size: 16),
                onPressed: item.quantity > 1 ? () => _step(-1) : null,
              ),
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'common.quantity'.tr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onQuantityTyped,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'common.increase'.tr,
                icon: const Icon(Symbols.add, size: 16),
                onPressed: () => _step(1),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppMoneyField(
                  initialValue: item.unitPrice,
                  label: 'transactions.unitPrice'.tr,
                  onChanged: (money) => widget.onChanged(widget.item.copyWith(unitPrice: money)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<String>(
            label: 'common.unit'.tr,
            hint: 'common.select'.tr,
            value: hasUnit ? item.unitId : null,
            options: unitOptions,
            onChanged: (value) {
              if (value != null) widget.onChanged(widget.item.copyWith(unitId: value));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!PlanFeatures.has(FeatureKey.discountRules))
            LockedFeatureCard(feature: FeatureKey.discountRules, title: 'transactions.promotionsBuy3Pay2'.tr)
          else
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
            Text('transactions.previouslyEnteredDiscountAmount'.trParams({'formatted': item.discount.formatted}), style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppMoneyField(
            initialValue: item.additionalCost,
            label: 'transactions.surchargeOptional'.tr,
            onChanged: (money) => widget.onChanged(widget.item.copyWith(additionalCost: money)),
          ),
          if (widget.onRemove != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: widget.onRemove,
              style: TextButton.styleFrom(foregroundColor: context.colors.error),
              icon: const Icon(Symbols.delete, size: 18),
              label: Text('transactions.removeProduct'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
