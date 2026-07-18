import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/auth/presentation/pages/profile_page.dart';
import 'package:buy_control/features/categories/presentation/bindings/categories_binding.dart';
import 'package:buy_control/features/categories/presentation/pages/categories_page.dart';
import 'package:buy_control/features/product_types/presentation/bindings/product_types_binding.dart';
import 'package:buy_control/features/product_types/presentation/pages/product_types_page.dart';
import 'package:buy_control/features/settings/presentation/bindings/settings_binding.dart';
import 'package:buy_control/features/settings/presentation/pages/settings_page.dart';
import 'package:buy_control/features/units/presentation/bindings/units_binding.dart';
import 'package:buy_control/features/units/presentation/pages/units_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  void _comingSoon() {
    Get.snackbar('Em breve', 'Este recurso ainda não está disponível.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = Get.find<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const AppText.title('Mais', fontSize: AppFontSizes.fz09)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            onTap: () => Get.to(() => const ProfilePage()),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent,
                  child: const Icon(LucideIcons.userCircle, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(currentUser?.name ?? 'Usuário', fontWeight: FontWeight.bold, fontSize: AppFontSizes.fz08),
                      const SizedBox(height: AppSpacing.xs),
                      AppText.subtitle(currentUser?.email ?? '', color: AppColors.textSecondary(isDark)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(LucideIcons.tag),
            title: const AppText('Categorias', fontWeight: FontWeight.w600),
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
            onTap: () => Get.to(() => const CategoriesPage(), binding: CategoriesBinding()),
          ),
          ListTile(
            leading: const Icon(LucideIcons.shapes),
            title: const AppText('Tipos de Produto', fontWeight: FontWeight.w600),
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
            onTap: () => Get.to(() => const ProductTypesPage(), binding: ProductTypesBinding()),
          ),
          ListTile(
            leading: const Icon(LucideIcons.ruler),
            title: const AppText('Unidades', fontWeight: FontWeight.w600),
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
            onTap: () => Get.to(() => const UnitsPage(), binding: UnitsBinding()),
          ),
          ListTile(
            leading: const Icon(LucideIcons.settings),
            title: const AppText('Configurações', fontWeight: FontWeight.w600),
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
            onTap: () => Get.to(() => const SettingsPage(), binding: SettingsBinding()),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(),
          ),
          AppText.subtitle('Em breve', color: AppColors.textSecondary(isDark)),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(LucideIcons.refreshCw, color: AppColors.textSecondary(isDark)),
            title: AppText('Sincronização', fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDark)),
            onTap: _comingSoon,
          ),
        ],
      ),
    );
  }
}
