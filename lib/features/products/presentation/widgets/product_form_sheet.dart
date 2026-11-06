import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/barcode_scanner_page.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/product_barcodes.dart';
import 'package:buy_control/features/products/presentation/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Formulário de criação/edição de produto. Todo o estado fica local ao
/// widget (rascunho) — nada é persistido até o usuário tocar em Salvar.
class ProductFormSheet extends StatefulWidget {
  final ProductEntity? product;

  /// Códigos já preenchidos num produto novo (ex.: código que acabou de ser
  /// lido e não estava cadastrado).
  final List<String> initialBarcodes;

  /// Chamado com o produto criado (só na criação).
  final void Function(ProductEntity product)? onCreated;

  const ProductFormSheet({super.key, this.product, this.initialBarcodes = const [], this.onCreated});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final controller = Get.find<ProductsController>();

  late final codeController = TextEditingController(text: widget.product?.code);
  late final barcodeController =
      TextEditingController(text: (widget.product?.barcodes ?? widget.initialBarcodes).join(', '));
  late final nameController = TextEditingController(text: widget.product?.name);
  late final descriptionController = TextEditingController(text: widget.product?.description);
  late final brandController = TextEditingController(text: widget.product?.brand);

  String? categoryId;
  String? productTypeId;
  String? defaultUnitId;
  Money? referencePrice;
  String? errorMessage;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    categoryId = widget.product?.categoryId;
    productTypeId = widget.product?.productTypeId;
    defaultUnitId = widget.product?.defaultUnitId;
    referencePrice = widget.product?.referencePrice;
  }

  @override
  void dispose() {
    codeController.dispose();
    barcodeController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    brandController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await BarcodeScannerPage.scanOnce(context);
    if (code == null || !mounted) return;
    final codes = ProductBarcodes.parseList(barcodeController.text);
    if (!codes.contains(code.lookupKey)) codes.add(code.lookupKey);
    setState(() => barcodeController.text = codes.join(', '));
  }

  Future<void> _submit() async {
    setState(() => submitting = true);
    final barcodes = ProductBarcodes.parseList(barcodeController.text);

    final String? error;
    if (widget.product != null) {
      error = await controller.edit(widget.product!.copyWith(
        code: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
        barcodes: barcodes,
        name: nameController.text,
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        brand: brandController.text.trim().isEmpty ? null : brandController.text.trim(),
        categoryId: categoryId,
        productTypeId: productTypeId,
        defaultUnitId: defaultUnitId,
        referencePrice: referencePrice,
      ));
    } else {
      error = await controller.create(
        code: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
        barcodes: barcodes,
        onCreated: widget.onCreated,
        name: nameController.text,
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        brand: brandController.text.trim().isEmpty ? null : brandController.text.trim(),
        categoryId: categoryId ?? '',
        productTypeId: productTypeId ?? '',
        defaultUnitId: defaultUnitId ?? '',
        referencePrice: referencePrice,
      );
    }

    if (!mounted) return;
    setState(() {
      submitting = false;
      errorMessage = error;
    });

    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = controller.categories
        .map((c) => AppDropdownOption(value: c.id, label: c.name))
        .toList();
    final productTypeOptions = controller.productTypes
        .map((t) => AppDropdownOption(value: t.id, label: t.name))
        .toList();
    final unitOptions = controller.units
        .map((u) => AppDropdownOption(value: u.id, label: '${u.name} (${u.abbreviation})'))
        .toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title(widget.product != null ? 'Editar produto' : 'Novo produto', fontSize: AppFontSizes.fz09),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(controller: nameController, label: 'Nome', hint: 'Arroz Tipo 1'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: brandController, label: 'Marca', hint: 'Camil'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: codeController, label: 'Código interno', hint: 'Opcional'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: barcodeController,
            label: 'Códigos de barras',
            hint: 'Opcional — separe vários com vírgula',
            keyboardType: TextInputType.number,
            suffix: IconButton(
              tooltip: 'Ler com a câmera',
              icon: const Icon(LucideIcons.scanBarcode, size: 20),
              onPressed: _scanBarcode,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Categoria',
            hint: 'Selecione',
            value: categoryId,
            options: categoryOptions,
            onChanged: (value) => setState(() => categoryId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Tipo de produto',
            hint: 'Selecione',
            value: productTypeId,
            options: productTypeOptions,
            onChanged: (value) => setState(() => productTypeId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Unidade padrão',
            hint: 'Selecione',
            value: defaultUnitId,
            options: unitOptions,
            onChanged: (value) => setState(() => defaultUnitId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppMoneyField(
            initialValue: referencePrice,
            label: 'Preço de referência',
            onChanged: (money) => referencePrice = money,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: descriptionController,
            label: 'Observações',
            hint: 'Opcional',
            maxLines: 3,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(errorMessage!, color: AppColors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Salvar', onPressed: submitting ? null : _submit),
        ],
      ),
    );
  }
}
