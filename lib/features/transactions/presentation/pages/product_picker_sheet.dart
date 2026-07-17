import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
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
import 'package:flutter/material.dart';
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
  final Set<String> _selectedIds = {};
  String _query = '';
  String? _categoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final categoriesResult = await _getCategories();
    categoriesResult.fold((data) => _categories = data, (_) {});
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final result = await _searchProducts(query: _query, categoryId: _categoryId);
    result.fold((data) => _products = data, (_) => _products = []);
    if (mounted) setState(() => _loading = false);
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _continue() {
    final selected = _products.where((p) => _selectedIds.contains(p.id)).toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.title('Selecionar produtos', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.md),
        SearchFieldDebounced(
          hint: 'Buscar produto',
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
              : _products.isEmpty
                  ? const EmptyStateView(title: 'Nenhum produto encontrado')
                  : ListView.separated(
                      itemCount: _products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final product = _products[i];
                        return SelectableListTile(
                          title: product.name,
                          subtitle: product.brand,
                          selected: _selectedIds.contains(product.id),
                          onTap: () => _toggle(product.id),
                        );
                      },
                    ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText('${_selectedIds.length} produtos selecionados', color: AppColors.textSecondary(isDark)),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Continuar', onPressed: _selectedIds.isEmpty ? null : _continue),
      ],
    );
  }
}
