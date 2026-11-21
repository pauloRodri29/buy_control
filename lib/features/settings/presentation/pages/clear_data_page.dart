import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/features/settings/domain/usecases/clear_app_data.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

class ClearDataPage extends StatelessWidget {
  const ClearDataPage({super.key});

  Future<void> _run(BuildContext context, ClearDataScope scope, {required String title, required String message}) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: 'settings.delete'.tr,
    );
    if (!confirmed) return;

    final clearAppData = Get.find<ClearAppData>();
    await clearAppData(scope);

    if (context.mounted) {
      AppFeedback.success('settings.operationWasCompleted'.tr, title: 'settings.dataDeleted'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.heading('settings.clearData'.tr, )),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppText.subtitle(
            'settings.eachOptionBelowPermanentlyDeletes'.tr,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ClearTile(
                  icon: Symbols.inventory_2,
                  label: 'common.boxes'.tr,
                  onTap: () => _run(
                    context,
                    ClearDataScope.boxes,
                    title: 'settings.deleteAllBoxes'.tr,
                    message: 'settings.removesAllBoxesTheirEntries'.tr,
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: Symbols.shopping_basket,
                  label: 'common.products'.tr,
                  onTap: () => _run(
                    context,
                    ClearDataScope.products,
                    title: 'settings.deleteAllProducts'.tr,
                    message: 'settings.removesWholeCatalogRegisteredProducts'.tr,
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: Symbols.history,
                  label: 'settings.purchaseHistory'.tr,
                  onTap: () => _run(
                    context,
                    ClearDataScope.history,
                    title: 'settings.deletePurchaseHistory'.tr,
                    message: 'settings.removesAllEntriesClosingsRecorded'.tr,
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: Symbols.view_kanban,
                  label: 'common.planning'.tr,
                  onTap: () => _run(
                    context,
                    ClearDataScope.planning,
                    title: 'settings.deleteAllPlanning'.tr,
                    message: 'settings.removesAllPlanningBoardsTheir'.tr,
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: Symbols.description,
                  label: 'settings.savedReports'.tr,
                  onTap: () => _run(
                    context,
                    ClearDataScope.reports,
                    title: 'settings.deleteSavedReports'.tr,
                    message: 'settings.removesAllFilterCombinationsSaved'.tr,
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: Symbols.palette,
                  label: 'settings.preferences'.tr,
                  onTap: () => _run(
                    context,
                    ClearDataScope.preferences,
                    title: 'settings.resetPreferences'.tr,
                    message: 'settings.restoresAppsAppearanceBehaviorPreferences'.tr,
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: Symbols.replay,
                  label: 'settings.resetEverything'.tr,
                  destructive: true,
                  onTap: () => _run(
                    context,
                    ClearDataScope.all,
                    title: 'settings.resetAppInitialState'.tr,
                    message: 'settings.deletesAllBoxesProductsPurchase'.tr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ClearTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.colors.error : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: AppText(label, fontWeight: FontWeight.w600, color: color),
      trailing: const Icon(Symbols.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
