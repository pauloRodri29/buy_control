import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_list_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/presentation/controllers/product_types_controller.dart';
import 'package:buy_control/features/product_types/presentation/widgets/product_type_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

class ProductTypesPage extends StatelessWidget {
  const ProductTypesPage({super.key});

  void _openForm(BuildContext context, {ProductTypeEntity? type}) {
    AppBottomSheet.show(context, child: ProductTypeFormSheet(productType: type));
  }

  Future<void> _delete(BuildContext context, ProductTypesController controller, ProductTypeEntity type) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'productTypes.deleteTypeName'.trParams({'name': type.name}),
      message: 'productTypes.productsEntriesAlreadyUseType'.tr,
    );
    if (confirmed) await controller.delete(type.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.heading('common.productTypes'.tr, )),
      body: GetBuilder<ProductTypesController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'common.unexpectedError'.tr, onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: Symbols.category,
                title: 'productTypes.noTypesRegistered'.tr,
                message: 'productTypes.createProductTypesClassifyCatalog'.tr,
                actionLabel: 'productTypes.newType'.tr,
                onAction: () => _openForm(context),
              );
            case ViewStatus.success:
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: controller.productTypes.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final type = controller.productTypes[i];
                  return AppListCard(
                    title: type.name,
                    locked: controller.isLocked(type.id),
                    onTap: controller.isLocked(type.id)
                        ? controller.showLockedPrompt
                        : () => _openForm(context, type: type),
                    actions: [
                      AppListCardAction('common.edit'.tr, () => _openForm(context, type: type)),
                      AppListCardAction('common.delete'.tr, () => _delete(context, controller, type), destructive: true),
                    ],
                  );
                },
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _openForm(context),
        child: const Icon(Symbols.add),
      ),
    );
  }
}
