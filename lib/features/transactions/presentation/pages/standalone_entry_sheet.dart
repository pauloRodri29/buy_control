import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/barcode_scanner_page.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/usecases/get_product_types.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/product_barcodes.dart';
import 'package:buy_control/features/products/domain/usecases/create_product.dart';
import 'package:buy_control/features/products/domain/usecases/delete_product.dart';
import 'package:buy_control/features/products/domain/usecases/get_products.dart';
import 'package:buy_control/features/products/presentation/bindings/products_binding.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_limit_prompt.dart';
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
import 'package:material_symbols_icons/symbols.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/presentation/plan_features.dart';

enum _DuplicateChoice { useExisting, createAnyway }

/// Lançamento avulso: um único item, sem precisar escolher um produto do
/// catálogo. Assim como no fluxo de seleção de produtos, nada é gravado
/// até o usuário tocar em "Confirmar". Com [initial], abre preenchido e
/// salva as alterações no lançamento existente (que precisa estar aberto).
///
/// "Salvar também como produto" abre os dados que só o produto tem
/// (categoria e tipo obrigatórios, marca, códigos) e cadastra o produto
/// junto, já vinculado ao lançamento. Nome, unidade e preço vêm do próprio
/// lançamento. Se o nome ou o código já pertencem a um produto, oferece
/// usar o existente em vez de duplicar.
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
  final _brandController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _codeController = TextEditingController();

  late Money _value = _initialItem?.unitPrice ?? Money.zero;
  late String? _categoryId = _initialItem?.categoryId;
  late String? _productTypeId = _initialItem?.productTypeId;
  late String? _unitId = _initialItem?.unitId;
  // A data não é editável no lançamento: novo usa "agora", edição mantém a original.
  late final DateTime _occurredAt = widget.initial?.occurredAt ?? DateTime.now();
  late DiscountRule? _discountRule = _initialItem?.discountRule;
  late bool _carryOver = widget.initial?.carryOver ?? true;

  /// Produto do catálogo a que o lançamento está vinculado: o que já vinha
  /// na edição, ou um existente escolhido para não duplicar.
  late String? _linkedProductId = _initialItem?.productId;

  /// Além de lançar, cadastra um produto novo no catálogo (e vincula o
  /// lançamento a ele), sem precisar sair da Box.
  bool _saveAsProduct = false;
  bool _checkingQuota = false;

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
  List<ProductEntity> _products = [];
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;

  ProductEntity? get _linkedProduct => _products.firstWhereOrNull((p) => p.id == _linkedProductId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categoriesResult = await Get.find<GetCategories>()();
    final productTypesResult = await Get.find<GetProductTypes>()(includeInactive: true);
    final unitsResult = await Get.find<GetUnits>()();
    final productsResult = await Get.find<GetProducts>()(includeInactive: true);

    categoriesResult.fold((data) => _categories = data, (_) {});
    productTypesResult.fold((data) => _productTypes = data, (_) {});
    unitsResult.fold((data) => _units = data, (_) {});
    productsResult.fold((data) => _products = data, (_) {});

    if (_units.isNotEmpty && !_units.any((u) => u.id == _unitId)) {
      final defaultUnit = _units.firstWhere((u) => u.abbreviation.toUpperCase() == 'UN', orElse: () => _units.first);
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
    _brandController.dispose();
    _barcodeController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Ao ligar a chave, já confere o limite de produtos do plano, para o
  /// usuário não descobrir só no "Confirmar".
  Future<void> _toggleSaveAsProduct(bool value) async {
    if (!value) {
      setState(() => _saveAsProduct = false);
      return;
    }
    if (Get.isRegistered<QuotaGuard>()) {
      setState(() => _checkingQuota = true);
      final limit = await Get.find<QuotaGuard>().ensureCanAdd(ResourceKey.products);
      if (!mounted) return;
      setState(() => _checkingQuota = false);
      if (limit != null) {
        await PlanLimitPrompt.show(FailurePresenter.present(limit));
        return;
      }
    }
    setState(() => _saveAsProduct = true);
  }

  /// Vincula o lançamento a um produto que já existe, em vez de criar outro.
  void _linkTo(ProductEntity product) {
    setState(() {
      _linkedProductId = product.id;
      _saveAsProduct = false;
      _categoryId ??= product.categoryId;
      _productTypeId ??= product.productTypeId;
      if (_titleController.text.trim().isEmpty) _titleController.text = product.name;
    });
  }

  void _unlink() => setState(() => _linkedProductId = null);

  Future<bool> _askUseExistingForBarcode(ProductEntity product) async {
    final use = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Symbols.barcode),
        title: Text('transactions.codeAlreadyRegistered'.tr),
        content: Text(
          'transactions.barcodeBelongsProductLinkEntryName'.trParams({'name': product.name}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('common.cancel'.tr)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('transactions.useProduct'.tr)),
        ],
      ),
    );
    return use ?? false;
  }

  Future<_DuplicateChoice?> _askDuplicateName(ProductEntity product) {
    return showDialog<_DuplicateChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Symbols.inventory_2),
        title: Text('transactions.productSameName'.tr),
        content: Text(
          'transactions.alreadyCatalogUseExistingOneName'.trParams({'name': product.name}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('common.back'.tr)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_DuplicateChoice.createAnyway),
            child: Text('transactions.createAnother'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_DuplicateChoice.useExisting),
            child: Text('transactions.useExisting'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final code = await BarcodeScannerPage.scanOnce(context);
    if (code == null || !mounted) return;

    final owner = ProductBarcodes.findConflict(_products, barcodes: [code.lookupKey]);
    if (owner != null) {
      if (await _askUseExistingForBarcode(owner) && mounted) _linkTo(owner);
      return;
    }

    final codes = ProductBarcodes.parseList(_barcodeController.text);
    if (!codes.contains(code.lookupKey)) codes.add(code.lookupKey);
    setState(() => _barcodeController.text = codes.join(', '));
  }

  /// Antes de criar o produto: código de barras ou nome que já existem
  /// viram a opção de usar o produto existente. Devolve `false` se o
  /// usuário preferiu voltar ao formulário.
  Future<bool> _resolveDuplicates(String title) async {
    final barcodes = ProductBarcodes.parseList(_barcodeController.text);
    final owner = ProductBarcodes.findConflict(_products, barcodes: barcodes);
    if (owner != null) {
      if (!await _askUseExistingForBarcode(owner)) return false;
      _linkTo(owner);
      return true;
    }

    final key = title.trim().toLowerCase();
    final sameName = _products.firstWhereOrNull((p) => !p.isDeleted && p.isActive && p.name.trim().toLowerCase() == key);
    if (sameName == null) return true;

    final choice = await _askDuplicateName(sameName);
    switch (choice) {
      case null:
        return false;
      case _DuplicateChoice.useExisting:
        _linkTo(sameName);
        return true;
      case _DuplicateChoice.createAnyway:
        return true;
    }
  }

  void _fail(String message) {
    setState(() {
      _submitting = false;
      _errorMessage = message;
    });
  }

  Future<void> _confirm() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'transactions.enterTitleEntry'.tr);
      return;
    }
    if (_unitId == null || _unitId!.isEmpty) {
      setState(() => _errorMessage = 'transactions.registerLeastOneUnitBefore'.tr);
      return;
    }
    if (_saveAsProduct && (_categoryId == null || _productTypeId == null)) {
      setState(() => _errorMessage = 'transactions.saveProductChooseCategoryType'.tr);
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    if (_saveAsProduct && !await _resolveDuplicates(title)) {
      if (mounted) setState(() => _submitting = false);
      return;
    }
    if (!mounted) return;

    // Produto novo: criado antes para o lançamento já nascer vinculado; se
    // o lançamento falhar, o produto é desfeito.
    String? createdProductId;
    if (_saveAsProduct) {
      if (!Get.isRegistered<CreateProduct>()) ProductsBinding().dependencies();
      final code = _codeController.text.trim();
      final brand = _brandController.text.trim();
      final created = await Get.find<CreateProduct>()(
        name: title,
        brand: brand.isEmpty ? null : brand,
        code: code.isEmpty ? null : code,
        barcodes: ProductBarcodes.parseList(_barcodeController.text),
        categoryId: _categoryId!,
        productTypeId: _productTypeId!,
        defaultUnitId: _unitId!,
        referencePrice: _value.isZero ? null : _value,
      );
      if (!mounted) return;
      if (created.isFailure) return _fail(FailurePresenter.present(created.failureOrNull!));
      createdProductId = created.dataOrNull!.id;
    }

    final result = await _saveTransaction(title, productId: createdProductId ?? _linkedProductId);
    if (result.isFailure && createdProductId != null) {
      await Get.find<DeleteProduct>()(createdProductId);
    }

    if (!mounted) return;
    result.fold(
      (_) => Navigator.of(context).pop(true),
      (failure) => _fail(FailurePresenter.present(failure)),
    );
  }

  Future<Result<void>> _saveTransaction(String title, {required String? productId}) {
    final initial = widget.initial;
    final item = TransactionItemEntity(
      id: _initialItem?.id ?? IdGenerator.generate(),
      transactionId: initial?.id ?? '',
      // Mantém o vínculo com o produto na edição (antes era perdido).
      productId: productId,
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

    if (initial == null) {
      return CreateTransaction(repository)(
        boxId: widget.boxId,
        title: title,
        occurredAt: _occurredAt,
        description: description,
        notes: notes,
        items: [item],
        carryOver: _carryOver,
      );
    }
    return UpdateTransaction(repository)(
      TransactionEntity(
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
      ),
    );
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
    final unitOptions = _units
        .map((u) => AppDropdownOption(value: u.id, label: '${u.name} (${u.abbreviation})'))
        .toList();

    Widget categoryField({required bool required}) => AppDropdown<String>(
          label: required ? 'transactions.category'.tr : 'transactions.categoryOptional'.tr,
          hint: 'common.select'.tr,
          value: _categoryId,
          options: categoryOptions,
          onChanged: (value) => setState(() => _categoryId = value),
        );
    Widget typeField({required bool required}) => AppDropdown<String>(
          label: required ? 'transactions.type'.tr : 'transactions.typeOptional'.tr,
          hint: 'common.select'.tr,
          value: _productTypeId,
          options: productTypeOptions,
          onChanged: (value) => setState(() => _productTypeId = value),
        );

    final linked = _linkedProductId != null;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading(widget.initial == null ? 'transactions.oneOffEntry'.tr : 'transactions.editOneOffEntry'.tr),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(controller: _titleController, label: 'common.title'.tr, hint: 'transactions.eGFarmersMarket'.tr),
          const SizedBox(height: AppSpacing.sm),
          if (linked)
            _LinkedProductTile(name: _linkedProduct?.name ?? _titleController.text, onUnlink: _unlink)
          else ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _saveAsProduct,
              onChanged: _checkingQuota ? null : _toggleSaveAsProduct,
              title: Text('transactions.alsoSaveProduct'.tr),
              subtitle: Text('transactions.addsCatalogLinksEntry'.tr),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _saveAsProduct
                  ? _ProductSection(
                      categoryField: categoryField(required: true),
                      typeField: typeField(required: true),
                      brandController: _brandController,
                      barcodeController: _barcodeController,
                      codeController: _codeController,
                      onScan: _scanBarcode,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _descriptionController, label: 'common.descriptionOptional'.tr, maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppMoneyField(
                  initialValue: _value,
                  label: 'common.value'.tr,
                  onChanged: (money) => setState(() => _value = money),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'common.quantity'.tr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!PlanFeatures.has(FeatureKey.discountRules))
            LockedFeatureCard(feature: FeatureKey.discountRules, title: 'transactions.promotionsBuy3Pay2'.tr)
          else
            DiscountRuleEditor(initialRule: _discountRule, onChanged: (rule) => setState(() => _discountRule = rule)),
          if (!_discount.isZero) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.subtitle('transactions.youSave'.tr),
                AppText('- ${_discount.formatted}', color: context.colors.primary, fontWeight: FontWeight.w600),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.subtitle('common.total'.tr),
                AppText((_value * _quantity - _discount).formatted, fontWeight: FontWeight.w600),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'common.unit'.tr,
            hint: 'common.select'.tr,
            value: _unitId,
            options: unitOptions,
            onChanged: (value) => setState(() => _unitId = value),
          ),
          // Com "salvar como produto", categoria e tipo ficam na seção do
          // produto (obrigatórios); sem ela, aqui embaixo e opcionais.
          if (!_saveAsProduct) ...[
            const SizedBox(height: AppSpacing.md),
            categoryField(required: false),
            const SizedBox(height: AppSpacing.md),
            typeField(required: false),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _notesController, label: 'transactions.noteOptional'.tr, maxLines: 2),
          const SizedBox(height: AppSpacing.sm),
          CarryOverSwitch(value: _carryOver, onChanged: (v) => setState(() => _carryOver = v)),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(_errorMessage!, color: context.colors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.initial == null ? 'common.confirm'.tr : 'transactions.saveChanges'.tr,
            onPressed: _submitting ? null : _confirm,
          ),
        ],
      ),
    );
  }
}

/// Dados que só o produto tem. Nome, unidade e preço vêm do lançamento.
class _ProductSection extends StatelessWidget {
  final Widget categoryField;
  final Widget typeField;
  final TextEditingController brandController;
  final TextEditingController barcodeController;
  final TextEditingController codeController;
  final VoidCallback onScan;

  const _ProductSection({
    required this.categoryField,
    required this.typeField,
    required this.brandController,
    required this.barcodeController,
    required this.codeController,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.inventory_2, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              AppText('transactions.productDetails'.tr, fontWeight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText.subtitle('transactions.nameUnitPriceComeFrom'.tr),
          const SizedBox(height: AppSpacing.md),
          categoryField,
          const SizedBox(height: AppSpacing.md),
          typeField,
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: brandController,
            label: 'transactions.brandOptional'.tr,
            hint: 'Camil',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: barcodeController,
            label: 'transactions.barcodesOptional'.tr,
            hint: 'transactions.separateMultipleCommas'.tr,
            keyboardType: TextInputType.number,
            suffix: IconButton(
              tooltip: 'common.scanCamera'.tr,
              icon: const Icon(Symbols.qr_code_scanner, size: 20),
              onPressed: onScan,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: codeController, label: 'transactions.internalCodeOptional'.tr),
        ],
      ),
    );
  }
}

/// Lançamento já vinculado a um produto do catálogo (na edição, ou ao
/// escolher um existente para não duplicar).
class _LinkedProductTile extends StatelessWidget {
  final String name;
  final VoidCallback onUnlink;
  const _LinkedProductTile({required this.name, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        children: [
          Icon(Symbols.link, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subtitle('transactions.linkedProduct'.tr),
                AppText(name, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(onPressed: onUnlink, child: Text('transactions.unlink'.tr)),
        ],
      ),
    );
  }
}
