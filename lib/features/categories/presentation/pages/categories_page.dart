import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_list_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/presentation/controllers/categories_controller.dart';
import 'package:buy_control/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  void _openForm(BuildContext context, {CategoryEntity? category}) {
    AppBottomSheet.show(context, child: CategoryFormSheet(category: category));
  }

  Future<void> _delete(BuildContext context, CategoriesController controller, CategoryEntity category) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'categories.deleteCategoryName'.trParams({'name': category.name}),
      message: 'categories.productsEntriesAlreadyUseCategory'.tr,
    );
    if (confirmed) await controller.delete(category.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.heading('common.categories'.tr, )),
      body: GetBuilder<CategoriesController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'common.unexpectedError'.tr, onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: Symbols.sell,
                title: 'categories.noCategoriesRegistered'.tr,
                message: 'categories.createCategoriesLikeDrinksCleaning'.tr,
                actionLabel: 'categories.newCategory'.tr,
                onAction: () => _openForm(context),
              );
            case ViewStatus.success:
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: controller.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final category = controller.categories[i];
                  return AppListCard(
                    title: category.name,
                    locked: controller.isLocked(category.id),
                    onTap: controller.isLocked(category.id)
                        ? controller.showLockedPrompt
                        : () => _openForm(context, category: category),
                    actions: [
                      AppListCardAction('common.edit'.tr, () => _openForm(context, category: category)),
                      AppListCardAction('common.delete'.tr, () => _delete(context, controller, category), destructive: true),
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
