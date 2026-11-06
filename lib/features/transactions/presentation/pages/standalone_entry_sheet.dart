import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/transactions/domain/entities/discount_rule.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/create_transaction.dart';
import 'package:buy_control/features/transactions/domain/usecases/update_transaction.dart';
import 'package:buy_control/features/transactions/presentation/widgets/carry_over_switch.dart';
import 'package:buy_control/features/transactions/presentation/widgets/discount_rule_editor.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lançamento avulso: um único item sem vínculo com o catálogo de
/// produtos. Assim como no fluxo de seleção de produtos, nada é gravado
/// até o usuário tocar em "Confirmar". Com [initial], abre preenchido e
/// salva as alterações no lançamento existente (que precisa estar aberto).
class StandaloneEntrySheet extends StatefulWidget {
  final String boxId;
  final TransactionEntity? initial;
  const StandaloneEntrySheet({super.key, required this.boxId, this.initial});

  @override
  State<StandaloneEntrySheet> createState() => _StandaloneEntrySheetState();
}

class _StandaloneEntrySheetState extends State<StandaloneEntrySheet> {
  TransactionItemEntity? get _initialItem => widget.initial?.items.firstOrNull;

  late final _titleController = TextEditingController(text: widget.initial?.title ?? _initialItem?.nameSnapshot ?? '');
  late final _descriptionController = TextEditingController(text: widget.initial?.description ?? '');
  late final _quantityController = TextEditingController(text: QuantityFormatter.format(_initialItem?.quantity ?? 1));
  late final _notesController = TextEditingController(text: widget.initial?.notes ?? '');

  late Money _value = _initialItem?.unitPrice ?? Money.zero;
  late String? _categoryId = _initialItem?.categoryId;
  late String? _productTypeId = _initialItem?.productTypeId;
  late String? _unitId = _initialItem?.unitId;
  // A data não é editável no lançamento: novo usa "agora", edição mantém a original.
  late final DateTime _occurredAt = widget.initial?.occurredAt ?? DateTime.now();
  late DiscountRule? _discountRule = _initialItem?.discountRule;
  late bool _carryOver = widget.initial?.carryOver ?? true;

  double get _quantity {
    final parsed = QuantityFormatter.parse(_quantityController.text) ?? 1;
    return parsed <= 0 ? 1 : parsed;
  }

  Money get _discount =>
      _discountRule?.calculate(itemQuantity: _quantity, unitPrice: _value) ??
      (_initialItem?.discountRule == null ? (_initialItem?.discount ?? Money.zero) : Money.zero);

  List<CategoryEntity> _categories = [];
  List<ProductTypeEntity> _productTypes = [];
  List<UnitEntity> _units = [];
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categoriesResult = await Get.find<GetCategories>()();
    final productTypesResult = await Get.find<GetProductTypes>()(includeInactive: true);
    final unitsResult = await Get.find<GetUnits>()();

    categoriesResult.fold((data) => _categories = data, (_) {});
    productTypesResult.fold((data) => _productTypes = data, (_) {});
    unitsResult.fold((data) => _units = data, (_) {});

    if (_units.isNotEmpty && !_units.any((u) => u.id == _unitId)) {
      final defaultUnit = _units.firstWhere(
        (u) => u.abbreviation.toUpperCase() == 'UN',
        orElse: () => _units.first,
      );
      _unitId = defaultUnit.id;
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Informe um título para o lançamento.');
      return;
    }
    if (_unitId == null || _unitId!.isEmpty) {
      setState(() => _errorMessage = 'Cadastre ao menos uma unidade antes de lançar.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final initial = widget.initial;
    final item = TransactionItemEntity(
      id: _initialItem?.id ?? IdGenerator.generate(),
      transactionId: initial?.id ?? '',
      nameSnapshot: title,
      categoryId: _categoryId,
      productTypeId: _productTypeId,
      unitId: _unitId!,
      quantity: _quantity,
      unitPrice: _value,
      discount: _discount,
      discountRule: _discountRule,
    );

    final description = _textOrNull(_descriptionController);
    final notes = _textOrNull(_notesController);

    final repository = Get.find<TransactionRepository>();
    final Result<void> result;
    if (initial == null) {
      result = await CreateTransaction(repository)(
        boxId: widget.boxId,
        title: title,
        occurredAt: _occurredAt,
        description: description,
        notes: notes,
        items: [item],
        carryOver: _carryOver,
      );
    } else {
      result = await UpdateTransaction(repository)(TransactionEntity(
        id: initial.id,
        boxId: initial.boxId,
        title: title,
        occurredAt: _occurredAt,
        description: description,
        notes: notes,
        discount: initial.discount,
        additionalCost: initial.additionalCost,
        items: [item],
        carryOver: _carryOver,
        createdAt: initial.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: initial.syncStatus,
        version: initial.version + 1,
      ));
    }

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

  static String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final categoryOptions = _categories.map((c) => AppDropdownOption(value: c.id, label: c.name)).toList();
    final productTypeOptions = _productTypes.map((t) => AppDropdownOption(value: t.id, label: t.name)).toList();
    final unitOptions =
        _units.map((u) => AppDropdownOption(value: u.id, label: '${u.name} (${u.abbreviation})')).toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title(
            widget.initial == null ? 'Lançamento avulso' : 'Editar lançamento avulso',
            fontSize: AppFontSizes.fz09,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(controller: _titleController, label: 'Título', hint: 'Ex: Feira livre'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _descriptionController, label: 'Descrição (opcional)', maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppMoneyField(
                  initialValue: _value,
                  label: 'Valor',
                  onChanged: (money) => setState(() => _value = money),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'Quantidade',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DiscountRuleEditor(
            initialRule: _discountRule,
            onChanged: (rule) => setState(() => _discountRule = rule),
          ),
          if (!_discount.isZero) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText.subtitle('Você economiza'),
                AppText('- ${_discount.formatted}', color: AppColors.accent, fontWeight: FontWeight.w600),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText.subtitle('Total'),
                AppText((_value * _quantity - _discount).formatted, fontWeight: FontWeight.w600),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Unidade',
            hint: 'Selecione',
            value: _unitId,
            options: unitOptions,
            onChanged: (value) => setState(() => _unitId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Categoria (opcional)',
            hint: 'Selecione',
            value: _categoryId,
            options: categoryOptions,
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Tipo (opcional)',
            hint: 'Selecione',
            value: _productTypeId,
            options: productTypeOptions,
            onChanged: (value) => setState(() => _productTypeId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _notesController, label: 'Observação (opcional)', maxLines: 2),
          const SizedBox(height: AppSpacing.sm),
          CarryOverSwitch(value: _carryOver, onChanged: (v) => setState(() => _carryOver = v)),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(_errorMessage!, color: AppColors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.initial == null ? 'Confirmar' : 'Salvar alterações',
            onPressed: _submitting ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
