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
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/presentation/controllers/product_types_controller.dart';
import 'package:buy_control/features/product_types/presentation/widgets/product_type_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductTypesPage extends StatelessWidget {
  const ProductTypesPage({super.key});

  void _openForm(BuildContext context, {ProductTypeEntity? type}) {
    AppBottomSheet.show(context, child: ProductTypeFormSheet(productType: type));
  }

  Future<void> _delete(BuildContext context, ProductTypesController controller, ProductTypeEntity type) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir o tipo "${type.name}"?',
      message: 'Produtos e lançamentos que já usam este tipo continuam funcionando normalmente.',
    );
    if (confirmed) await controller.delete(type.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.title('Tipos de Produto', fontSize: AppFontSizes.fz09)),
      body: GetBuilder<ProductTypesController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: LucideIcons.shapes,
                title: 'Nenhum tipo cadastrado',
                message: 'Crie tipos de produto para classificar seu catálogo.',
                actionLabel: 'Novo tipo',
                onAction: () => _openForm(context),
              );
            case ViewStatus.success:
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: controller.productTypes.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final type = controller.productTypes[i];
                  return ListTile(
                    title: AppText(type.name, fontWeight: FontWeight.w600),
                    onTap: () => _openForm(context, type: type),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      onPressed: () => _delete(context, controller, type),
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
