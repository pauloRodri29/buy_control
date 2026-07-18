import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:buy_control/features/transactions/domain/usecases/create_transaction.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lançamento avulso: um único item sem vínculo com o catálogo de
/// produtos. Assim como no fluxo de seleção de produtos, nada é gravado
/// até o usuário tocar em "Confirmar".
class StandaloneEntrySheet extends StatefulWidget {
  final String boxId;
  const StandaloneEntrySheet({super.key, required this.boxId});

  @override
  State<StandaloneEntrySheet> createState() => _StandaloneEntrySheetState();
}

class _StandaloneEntrySheetState extends State<StandaloneEntrySheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  Money _value = Money.zero;
  String? _categoryId;
  String? _productTypeId;
  String? _unitId;
  DateTime _occurredAt = DateTime.now();
  bool _recurring = false;

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
    final productTypesResult = await Get.find<GetProductTypes>()();
    final unitsResult = await Get.find<GetUnits>()();

    categoriesResult.fold((data) => _categories = data, (_) {});
    productTypesResult.fold((data) => _productTypes = data, (_) {});
    unitsResult.fold((data) => _units = data, (_) {});

    if (_units.isNotEmpty) {
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _occurredAt = picked);
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
    final quantity = double.tryParse(_quantityController.text.trim().replaceAll(',', '.')) ?? 1;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final item = TransactionItemEntity(
      id: IdGenerator.generate(),
      transactionId: '',
      nameSnapshot: title,
      categoryId: _categoryId,
      unitId: _unitId!,
      quantity: quantity <= 0 ? 1 : quantity,
      unitPrice: _value,
    );

    final notesParts = [
      if (_descriptionController.text.trim().isNotEmpty) _descriptionController.text.trim(),
      if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
    ];

    final createTransaction = CreateTransaction(Get.find<TransactionRepository>());
    final result = await createTransaction(
      boxId: widget.boxId,
      title: title,
      occurredAt: _occurredAt,
      notes: notesParts.isEmpty ? null : notesParts.join(' — '),
      items: [item],
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
    if (_loading) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
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
          AppText.title('Lançamento avulso', fontSize: AppFontSizes.fz09),
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
                  onChanged: (money) => _value = money,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'Quantidade',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
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
          // O tipo de produto ainda não tem campo correspondente em
          // TransactionItemEntity — coletado aqui para o usuário organizar
          // o lançamento, mas não é persistido.
          AppDropdown<String>(
            label: 'Tipo (opcional)',
            hint: 'Selecione',
            value: _productTypeId,
            options: productTypeOptions,
            onChanged: (value) => setState(() => _productTypeId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Data'),
              child: AppText(DateTimeFormatter.ddMMyyyy(_occurredAt)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _notesController, label: 'Observação (opcional)', maxLines: 2),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Checkbox(value: _recurring, onChanged: (v) => setState(() => _recurring = v ?? false)),
              const Expanded(child: AppText('Repetir mensalmente (em breve)')),
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
