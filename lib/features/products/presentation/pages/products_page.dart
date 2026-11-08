import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/app/widgets/search_field_debounced.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/products/presentation/controllers/products_controller.dart';
import 'package:buy_control/features/products/presentation/widgets/product_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  void _openForm(BuildContext context, {ProductEntity? product}) {
    AppBottomSheet.show(context, child: ProductFormSheet(product: product));
  }

  Future<void> _delete(BuildContext context, ProductsController controller, ProductEntity product) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir o produto "${product.name}"?',
      message:
          'O produto deixará de aparecer no catálogo, mas lançamentos antigos que já usam ele '
          'continuam mostrando o nome e preço registrados na época.',
    );
    if (confirmed) await controller.delete(product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.title('Produtos', fontSize: AppFontSizes.fz09)),
      body: GetBuilder<ProductsController>(
        builder: (controller) {
          final showFilters = controller.status != ViewStatus.initial && controller.status != ViewStatus.loading;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: SearchFieldDebounced(hint: 'Buscar produto', onChanged: controller.search),
              ),
              if (showFilters && controller.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: FilterChipsBar(
                    options: controller.categories.map((c) => FilterChipOption(key: c.id, label: c.name)).toList(),
                    selectedKey: controller.selectedCategoryId,
                    onSelected: controller.filterByCategory,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _buildBody(context, controller)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _openForm(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProductsController controller) {
    switch (controller.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const LoadingSkeletonList();
      case ViewStatus.error:
        return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
      case ViewStatus.empty:
        return EmptyStateView(
          icon: LucideIcons.package,
          title: 'Nenhum produto encontrado',
          message: 'Cadastre produtos para usar nas compras e nos lançamentos.',
          actionLabel: 'Novo produto',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          itemCount: controller.products.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final product = controller.products[i];
            return _ProductCard(
              product: product,
              categoryName: controller.categoryName(product.categoryId),
              productTypeName: controller.productTypeName(product.productTypeId),
              unitAbbreviation: controller.unitAbbreviation(product.defaultUnitId),
              onTap: () => _openForm(context, product: product),
              onDelete: () => _delete(context, controller, product),
            );
          },
        );
    }
  }
}

/// Card de produto no padrão das listas do app (mesmo layout de `_BoxCard`):
/// nome em destaque, preço de referência em verde, metadados em subtítulo e
/// ações no menu ⋮.
class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final String categoryName;
  final String productTypeName;
  final String unitAbbreviation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.productTypeName,
    required this.unitAbbreviation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = product.referencePrice;
    final brand = product.brand;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  product.name,
                  fontWeight: FontWeight.bold,
                  fontSize: AppFontSizes.fz08,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand != null && brand.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AppText.subtitle(brand, color: AppColors.textSecondary(isDark)),
                ],
                const SizedBox(height: AppSpacing.xs),
                price == null
                    ? AppText('Sem preço de referência', color: AppColors.textSecondary(isDark))
                    : AppText(
                        unitAbbreviation.isEmpty || unitAbbreviation == '—'
                            ? price.formatted
                            : '${price.formatted} / $unitAbbreviation',
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                const SizedBox(height: AppSpacing.xs),
                AppText.subtitle('$categoryName • $productTypeName', color: AppColors.textSecondary(isDark)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onTap();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
