import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_circle_button.dart';
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
      message: 'O produto deixará de aparecer no catálogo, mas lançamentos antigos que já usam ele '
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
                    options: controller.categories
                        .map((c) => FilterChipOption(key: c.id, label: c.name))
                        .toList(),
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
      floatingActionButton: AppCircleButton(icon: LucideIcons.plus, onPressed: () => _openForm(context)),
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          itemCount: controller.products.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final product = controller.products[i];
            return ListTile(
              title: AppText(product.name, fontWeight: FontWeight.w600),
              subtitle: AppText.subtitle(
                '${controller.categoryName(product.categoryId)} • ${controller.productTypeName(product.productTypeId)} • '
                '${product.referencePrice?.formatted ?? '—'}',
              ),
              onTap: () => _openForm(context, product: product),
              trailing: IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                onPressed: () => _delete(context, controller, product),
              ),
            );
          },
        );
    }
  }
}
