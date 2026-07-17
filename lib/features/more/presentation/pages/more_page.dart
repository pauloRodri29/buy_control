import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/categories/presentation/bindings/categories_binding.dart';
import 'package:buy_control/features/categories/presentation/pages/categories_page.dart';
import 'package:buy_control/features/product_types/presentation/bindings/product_types_binding.dart';
import 'package:buy_control/features/product_types/presentation/pages/product_types_page.dart';
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

    return Scaffold(
      appBar: AppBar(title: const AppText.title('Mais', fontSize: AppFontSizes.fz09)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(),
          ),
          AppText.subtitle('Em breve', color: AppColors.textSecondary(isDark)),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(LucideIcons.settings, color: AppColors.textSecondary(isDark)),
            title: AppText('Configurações', fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDark)),
            onTap: _comingSoon,
          ),
          ListTile(
            leading: Icon(LucideIcons.hardDriveDownload, color: AppColors.textSecondary(isDark)),
            title: AppText('Backup', fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDark)),
            onTap: _comingSoon,
          ),
          ListTile(
            leading: Icon(LucideIcons.fileUp, color: AppColors.textSecondary(isDark)),
            title: AppText(
              'Importação e Exportação',
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(isDark),
            ),
            onTap: _comingSoon,
          ),
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
