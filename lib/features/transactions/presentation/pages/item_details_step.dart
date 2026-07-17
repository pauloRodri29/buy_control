import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Resultado deste passo: os itens ainda não persistidos, mais a data e a
/// observação do lançamento como um todo (campos que vivem na transação,
/// não em cada item — por isso são pedidos uma única vez aqui, e não em
/// cada mini-formulário de produto).
class ItemsDraftResult {
  final List<TransactionItemEntity> items;
  final DateTime occurredAt;
  final String? notes;
  const ItemsDraftResult({required this.items, required this.occurredAt, this.notes});
}

class ItemDetailsStep extends StatefulWidget {
  final List<ProductEntity> products;
  const ItemDetailsStep({super.key, required this.products});

  @override
  State<ItemDetailsStep> createState() => _ItemDetailsStepState();
}

class _ItemFormControllers {
  final ProductEntity product;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  final TextEditingController discount;
  final TextEditingController additionalCost;
  String unitId;

  _ItemFormControllers(this.product)
      : quantity = TextEditingController(text: '1'),
        unitPrice = TextEditingController(
          text: product.referencePrice != null ? product.referencePrice!.toDouble().toStringAsFixed(2) : '',
        ),
        discount = TextEditingController(),
        additionalCost = TextEditingController(),
        unitId = product.defaultUnitId;

  void dispose() {
    quantity.dispose();
    unitPrice.dispose();
    discount.dispose();
    additionalCost.dispose();
  }
}

class _ItemDetailsStepState extends State<ItemDetailsStep> {
  late final List<_ItemFormControllers> _forms = widget.products.map((p) => _ItemFormControllers(p)).toList();
  final _notesController = TextEditingController();
  List<UnitEntity> _units = [];
  DateTime _occurredAt = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final result = await Get.find<GetUnits>()();
    result.fold((data) {
      if (!mounted) return;
      setState(() => _units = data);
    }, (_) {});
  }

  @override
  void dispose() {
    for (final form in _forms) {
      form.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Money? _parseMoney(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed.replaceAll(',', '.'));
    return value == null ? null : Money.fromReais(value);
  }

  void _continue() {
    final items = <TransactionItemEntity>[];
    for (final form in _forms) {
      final quantity = double.tryParse(form.quantity.text.trim().replaceAll(',', '.'));
      if (quantity == null || quantity <= 0) {
        setState(() => _errorMessage = 'Quantidade inválida para "${form.product.name}".');
        return;
      }
      final unitPrice = _parseMoney(form.unitPrice.text) ?? Money.zero;
      items.add(TransactionItemEntity(
        id: IdGenerator.generate(),
        transactionId: '',
        productId: form.product.id,
        nameSnapshot: form.product.name,
        categoryId: form.product.categoryId,
        unitId: form.unitId,
        quantity: quantity,
        unitPrice: unitPrice,
        discount: _parseMoney(form.discount.text) ?? Money.zero,
        additionalCost: _parseMoney(form.additionalCost.text) ?? Money.zero,
      ));
    }

    Navigator.of(context).pop(ItemsDraftResult(
      items: items,
      occurredAt: _occurredAt,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.title('Detalhes dos itens', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Data',
              filled: true,
              fillColor: AppColors.surfaceVariant(isDark),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            child: AppText(DateTimeFormatter.ddMMyyyy(_occurredAt)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _notesController, label: 'Observação (opcional)', maxLines: 2),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.separated(
            itemCount: _forms.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _ItemForm(form: _forms[i], units: _units),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppText(_errorMessage!, color: AppColors.error),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Continuar', onPressed: _continue),
      ],
    );
  }
}

class _ItemForm extends StatefulWidget {
  final _ItemFormControllers form;
  final List<UnitEntity> units;
  const _ItemForm({required this.form, required this.units});

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unitOptions =
        widget.units.map((u) => AppDropdownOption(value: u.id, label: '${u.name} (${u.abbreviation})')).toList();
    final hasUnit = unitOptions.any((o) => o.value == widget.form.unitId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(widget.form.product.name, fontWeight: FontWeight.w600),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: widget.form.quantity,
                  label: 'Quantidade',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: widget.form.unitPrice,
                  label: 'Preço unitário',
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<String>(
            label: 'Unidade',
            hint: 'Selecione',
            value: hasUnit ? widget.form.unitId : null,
            options: unitOptions,
            onChanged: (value) => setState(() => widget.form.unitId = value ?? widget.form.unitId),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: widget.form.discount,
                  label: 'Desconto (opcional)',
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: widget.form.additionalCost,
                  label: 'Acréscimo (opcional)',
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
