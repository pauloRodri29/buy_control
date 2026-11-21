import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/app/widgets/search_field_debounced.dart';
import 'package:buy_control/app/widgets/selectable_list_tile.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/domain/usecases/search_products.dart';
import 'package:buy_control/features/products/presentation/bindings/products_binding.dart';
import 'package:buy_control/features/products/presentation/controllers/products_controller.dart';
import 'package:buy_control/features/products/presentation/widgets/product_form_sheet.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

/// Seleção de produtos do catálogo para um lançamento. Nada é persistido
/// aqui — a lista escolhida só vira dado real quando o fluxo de compra é
/// confirmado no último passo (`PurchaseSummaryStep`).
class ProductPickerSheet extends StatefulWidget {
  const ProductPickerSheet({super.key});

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  final _searchProducts = Get.find<SearchProducts>();
  final _getCategories = Get.find<GetCategories>();

  List<ProductEntity> _products = [];
  List<CategoryEntity> _categories = [];
  /// Selecionados por id. Guarda o produto (não só o id) para a seleção
  /// sobreviver a uma busca/filtro que tire o produto da lista visível.
  final Map<String, ProductEntity> _selected = {};
  String _query = '';
  String? _categoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Produtos que passaram do limite do plano: não aparecem para seleção.
  Set<String> _locked = const {};

  Future<void> _init() async {
    final categoriesResult = await _getCategories();
    categoriesResult.fold((data) => _categories = data, (_) {});
    _locked = await Get.find<SubscriptionController>().lockedIds(ResourceKey.products);
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final result = await _searchProducts(query: _query, categoryId: _categoryId);
    result.fold((data) => _products = data.where((p) => !_locked.contains(p.id)).toList(), (_) => _products = []);
    if (mounted) setState(() => _loading = false);
  }

  void _toggle(ProductEntity product) {
    setState(() {
      if (_selected.remove(product.id) == null) _selected[product.id] = product;
    });
  }

  void _continue() => Navigator.of(context).pop(_selected.values.toList());

  /// Mostra o atalho "Cadastrar" quando há um termo buscado que não é
  /// exatamente o nome de um produto já listado.
  bool get _canCreateFromQuery {
    final term = _query.trim().toLowerCase();
    return term.isNotEmpty && !_products.any((p) => p.name.trim().toLowerCase() == term);
  }

  /// Cadastra no catálogo o produto que não existe, sem sair da compra, e
  /// já o deixa selecionado.
  Future<void> _createFromQuery() async {
    if (!Get.isRegistered<ProductsController>()) ProductsBinding().dependencies();
    ProductEntity? created;
    await AppBottomSheet.show<void>(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: ProductFormSheet(initialName: _query.trim(), onCreated: (product) => created = product),
    );
    final product = created;
    if (product == null || !mounted) return;
    setState(() {
      _selected[product.id] = product;
      _products = [product, ..._products];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading('transactions.selectProducts'.tr, ),
        const SizedBox(height: AppSpacing.md),
        SearchFieldDebounced(
          hint: 'common.searchProduct'.tr,
          onChanged: (value) {
            _query = value;
            _loadProducts();
          },
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          FilterChipsBar(
            options: _categories.map((c) => FilterChipOption(key: c.id, label: c.name)).toList(),
            selectedKey: _categoryId,
            onSelected: (key) {
              _categoryId = key;
              _loadProducts();
            },
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty && !_canCreateFromQuery
                  ? EmptyStateView(title: 'common.noProductsFound'.tr)
                  : ListView(
                      children: [
                        if (_canCreateFromQuery) ...[
                          ListTile(
                            onTap: _createFromQuery,
                            tileColor: context.colors.primaryContainer,
                            textColor: context.colors.onPrimaryContainer,
                            iconColor: context.colors.onPrimaryContainer,
                            leading: const Icon(Symbols.add),
                            title: Text('transactions.addName'.trParams({'trim': _query.trim()})),
                            subtitle: Text('transactions.becomesCatalogProductAddedPurchase'.tr),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        for (final product in _products) ...[
                          SelectableListTile(
                            title: product.name,
                            subtitle: product.brand,
                            selected: _selected.containsKey(product.id),
                            onTap: () => _toggle(product),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText(
          _selected.length == 1 ? 'transactions.n1ProductSelected'.tr : 'transactions.productsSelectedCount'.trParams({'length': '${_selected.length}'}),
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'common.continue'.tr, onPressed: _selected.isEmpty ? null : _continue),
      ],
    );
  }
}
