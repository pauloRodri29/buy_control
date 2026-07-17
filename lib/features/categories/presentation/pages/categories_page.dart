import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_circle_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/presentation/controllers/categories_controller.dart';
import 'package:buy_control/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  void _openForm(BuildContext context, {CategoryEntity? category}) {
    AppBottomSheet.show(context, child: CategoryFormSheet(category: category));
  }

  Future<void> _delete(BuildContext context, CategoriesController controller, CategoryEntity category) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir a categoria "${category.name}"?',
      message: 'Produtos e lançamentos que já usam esta categoria continuam funcionando normalmente.',
    );
    if (confirmed) await controller.delete(category.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.title('Categorias', fontSize: AppFontSizes.fz09)),
      body: GetBuilder<CategoriesController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: LucideIcons.tag,
                title: 'Nenhuma categoria cadastrada',
                message: 'Crie categorias como Bebidas ou Limpeza para organizar seus produtos.',
                actionLabel: 'Nova categoria',
                onAction: () => _openForm(context),
              );
            case ViewStatus.success:
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: controller.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final category = controller.categories[i];
                  return ListTile(
                    title: AppText(category.name, fontWeight: FontWeight.w600),
                    onTap: () => _openForm(context, category: category),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      onPressed: () => _delete(context, controller, category),
                    ),
                  );
                },
              );
          }
        },
      ),
      floatingActionButton: AppCircleButton(icon: LucideIcons.plus, onPressed: () => _openForm(context)),
    );
  }
}
