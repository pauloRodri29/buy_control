import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/barcode_scanner_page.dart';
import 'package:buy_control/app/widgets/text_input_dialog.dart';
import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/usecases/find_product_by_barcode.dart';
import 'package:buy_control/features/products/domain/usecases/link_barcode_to_product.dart';
import 'package:buy_control/features/products/presentation/bindings/products_binding.dart';
import 'package:buy_control/features/products/presentation/controllers/products_controller.dart';
import 'package:buy_control/features/products/presentation/widgets/product_form_sheet.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/presentation/pages/product_picker_sheet.dart';
import 'package:buy_control/features/transactions/presentation/pages/scale_label_sheet.dart';
import 'package:buy_control/features/transactions/presentation/pages/unknown_barcode_sheet.dart';
import 'package:buy_control/features/transactions/presentation/purchase_draft.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Abre a câmera em "modo carrinho" e vai colocando no [draft] cada
/// produto lido. Nada é gravado como lançamento aqui — o rascunho segue
/// para o editor de itens/resumo como no fluxo normal. (Só o cadastro de
/// produto novo e o vínculo de código a produto são gravados na hora,
/// porque fazem parte do catálogo, não da compra.)
///
/// - Código conhecido → adiciona o produto (ou soma +1 se já estiver).
/// - Etiqueta de balança → confirma preço/peso e adiciona um item próprio.
/// - Código desconhecido → cadastrar, vincular a produto existente,
///   lançar avulso ou ignorar.
Future<void> scanIntoDraft(BuildContext context, PurchaseDraft draft) async {
  final units = (await Get.find<GetUnits>()()).dataOrNull ?? const <UnitEntity>[];
  if (!context.mounted) return;
  final handler = _ScanHandler(draft: draft, units: units);
  await BarcodeScannerPage.scanContinuous(context, onScanned: handler.handle);
}

class _ScanHandler {
  final PurchaseDraft draft;
  final List<UnitEntity> units;

  _ScanHandler({required this.draft, required this.units});

  final _findProduct = Get.find<FindProductByBarcode>();
  final _linkBarcode = Get.find<LinkBarcodeToProduct>();

  String? _unitIdByAbbreviation(String abbreviation) =>
      units.where((u) => u.abbreviation.toUpperCase() == abbreviation).firstOrNull?.id;

  String? get _defaultUnitId => _unitIdByAbbreviation('UN') ?? units.firstOrNull?.id;

  Future<String?> handle(BuildContext context, ScannedCode code) async {
    final found = await _findProduct(code);
    if (found.isFailure) return FailurePresenter.present(found.failureOrNull!);
    if (!context.mounted) return null;
    final product = found.dataOrNull;

    if (code.isScaleLabel) return _handleScaleLabel(context, code, product);
    if (product != null) return _addProduct(product);
    return _handleUnknown(context, code);
  }

  String _addProduct(ProductEntity product) {
    draft.addProducts([product]);
    final quantity = draft.quantityOf(product.id);
    final label = QuantityFormatter.format(quantity);
    return '+1 ${product.name} (total: $label)';
  }

  Future<String?> _handleScaleLabel(BuildContext context, ScannedCode code, ProductEntity? product) async {
    final result = await AppBottomSheet.show<ScaleLabelResult>(
      context,
      child: ScaleLabelSheet(code: code, product: product),
    );
    if (result == null) return null;

    final chosen = result.product;
    if (chosen != null && result.linkProduct) {
      final linked = await _linkBarcode(productId: chosen.id, code: code);
      if (linked.isFailure) return FailurePresenter.present(linked.failureOrNull!);
    }

    final byWeight = result.mode == ScaleValueMode.weight;
    final unitId = byWeight
        ? (_unitIdByAbbreviation('KG') ?? chosen?.defaultUnitId ?? _defaultUnitId)
        : (chosen?.defaultUnitId ?? _defaultUnitId);
    if (unitId == null) return 'Cadastre ao menos uma unidade antes de lançar.';

    draft.addItem(TransactionItemEntity(
      id: IdGenerator.generate(),
      transactionId: '',
      productId: chosen?.id,
      nameSnapshot: result.name,
      categoryId: chosen?.categoryId,
      unitId: unitId,
      quantity: byWeight ? result.weightKg : 1,
      unitPrice: byWeight ? (chosen?.referencePrice ?? Money.zero) : result.price,
    ));
    return byWeight
        ? '+ ${result.name} (${result.weightKg.toStringAsFixed(3).replaceAll('.', ',')} kg)'
        : '+ ${result.name} (${result.price.formatted})';
  }

  Future<String?> _handleUnknown(BuildContext context, ScannedCode code) async {
    final action = await AppBottomSheet.show<UnknownBarcodeAction>(
      context,
      child: UnknownBarcodeSheet(code: code),
    );
    if (action == null || !context.mounted) return null;

    switch (action) {
      case UnknownBarcodeAction.create:
        return _createProduct(context, code);
      case UnknownBarcodeAction.link:
        return _linkToExisting(context, code);
      case UnknownBarcodeAction.standalone:
        return _addStandalone(context);
    }
  }

  Future<String?> _createProduct(BuildContext context, ScannedCode code) async {
    if (!Get.isRegistered<ProductsController>()) ProductsBinding().dependencies();
    ProductEntity? created;
    await AppBottomSheet.show<void>(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: ProductFormSheet(initialBarcodes: [code.lookupKey], onCreated: (product) => created = product),
    );
    final product = created;
    return product == null ? null : _addProduct(product);
  }

  Future<String?> _linkToExisting(BuildContext context, ScannedCode code) async {
    final selected = await AppBottomSheet.show<List<ProductEntity>>(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: const ProductPickerSheet(),
    );
    if (selected == null || selected.isEmpty) return null;

    final linked = await _linkBarcode(productId: selected.first.id, code: code);
    return linked.fold(_addProduct, (failure) => FailurePresenter.present(failure));
  }

  Future<String?> _addStandalone(BuildContext context) async {
    final unitId = _defaultUnitId;
    if (unitId == null) return 'Cadastre ao menos uma unidade antes de lançar.';

    final name = await TextInputDialog.show(
      context,
      title: 'Nome do item',
      hint: 'Ex.: Biscoito da padaria',
      confirmLabel: 'Adicionar',
      textCapitalization: TextCapitalization.sentences,
    );
    if (name == null || name.isEmpty) return null;

    draft.addItem(TransactionItemEntity(
      id: IdGenerator.generate(),
      transactionId: '',
      nameSnapshot: name,
      unitId: unitId,
      quantity: 1,
      unitPrice: Money.zero,
    ));
    return '+ $name (informe o preço na lista de itens)';
  }
}
