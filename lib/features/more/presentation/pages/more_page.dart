import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/auth/presentation/pages/profile_page.dart';
import 'package:buy_control/features/categories/presentation/bindings/categories_binding.dart';
import 'package:buy_control/features/categories/presentation/pages/categories_page.dart';
import 'package:buy_control/features/product_types/presentation/bindings/product_types_binding.dart';
import 'package:buy_control/features/product_types/presentation/pages/product_types_page.dart';
import 'package:buy_control/features/reports/presentation/bindings/reports_binding.dart';
import 'package:buy_control/features/reports/presentation/pages/reports_page.dart';
import 'package:buy_control/features/settings/presentation/bindings/settings_binding.dart';
import 'package:buy_control/features/settings/presentation/pages/settings_page.dart';
import 'package:buy_control/features/units/presentation/bindings/units_binding.dart';
import 'package:buy_control/features/units/presentation/pages/units_page.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/pages/my_plan_page.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_badge.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  void _comingSoon() {
    AppFeedback.info('common.featureNotAvailableYet'.tr, title: 'common.comingSoon'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Get.find<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(title: AppText.heading('common.more'.tr, )),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            onTap: () => Get.to(() => const ProfilePage()),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.colors.primary,
                  child: Icon(Symbols.account_circle, color: context.colors.onPrimary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(currentUser?.name ?? 'more.user'.tr, fontWeight: FontWeight.bold, ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText.subtitle(currentUser?.email ?? ''),
                      const SizedBox(height: AppSpacing.sm),
                      GetBuilder<SubscriptionController>(
                        builder: (subscription) => GestureDetector(
                          onTap: () => Get.to(() => const MyPlanPage()),
                          child: PlanBadge(plan: subscription.plan),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Symbols.chevron_right, size: 18),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(Symbols.bar_chart),
            title: AppText('common.reports'.tr, fontWeight: FontWeight.w600),
            subtitle: AppText.subtitle('more.actualSpendingForecastGoals'.tr),
            trailing: const Icon(Symbols.chevron_right, size: 18),
            onTap: () => Get.to(() => const ReportsPage(), binding: ReportsBinding()),
          ),
          ListTile(
            leading: const Icon(Symbols.sell),
            title: AppText('common.categories'.tr, fontWeight: FontWeight.w600),
            trailing: const Icon(Symbols.chevron_right, size: 18),
            onTap: () => Get.to(() => const CategoriesPage(), binding: CategoriesBinding()),
          ),
          ListTile(
            leading: const Icon(Symbols.category),
            title: AppText('common.productTypes'.tr, fontWeight: FontWeight.w600),
            trailing: const Icon(Symbols.chevron_right, size: 18),
            onTap: () => Get.to(() => const ProductTypesPage(), binding: ProductTypesBinding()),
          ),
          ListTile(
            leading: const Icon(Symbols.straighten),
            title: AppText('common.units'.tr, fontWeight: FontWeight.w600),
            trailing: const Icon(Symbols.chevron_right, size: 18),
            onTap: () => Get.to(() => const UnitsPage(), binding: UnitsBinding()),
          ),
          ListTile(
            leading: const Icon(Symbols.settings),
            title: AppText('common.settings'.tr, fontWeight: FontWeight.w600),
            trailing: const Icon(Symbols.chevron_right, size: 18),
            onTap: () => Get.to(() => const SettingsPage(), binding: SettingsBinding()),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(),
          ),
          AppText.subtitle('common.comingSoon'.tr),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(Symbols.refresh, color: context.colors.onSurfaceVariant),
            title: AppText('more.sync'.tr, fontWeight: FontWeight.w600, color: context.colors.onSurfaceVariant),
            onTap: _comingSoon,
          ),
        ],
      ),
    );
  }
}
