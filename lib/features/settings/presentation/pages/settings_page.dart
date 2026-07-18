import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/auth/presentation/pages/profile_page.dart';
import 'package:buy_control/features/backup/presentation/backup_actions.dart';
import 'package:buy_control/features/settings/presentation/bindings/settings_binding.dart';
import 'package:buy_control/features/settings/presentation/pages/clear_data_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar seus dados.',
      confirmLabel: 'Sair',
    );
    if (confirmed) await Get.find<AuthController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const AppText.title('Configurações', fontSize: AppFontSizes.fz09)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SectionHeader('Conta'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.userCircle),
                  title: const AppText('Perfil', fontWeight: FontWeight.w600),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => Get.to(() => const ProfilePage()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.logOut),
                  title: const AppText('Sair', fontWeight: FontWeight.w600),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader('Dados'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.uploadCloud),
                  title: const AppText('Exportar dados', fontWeight: FontWeight.w600),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => runExportBackup(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.downloadCloud),
                  title: const AppText('Importar dados', fontWeight: FontWeight.w600),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => runImportBackup(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(LucideIcons.trash2, color: AppColors.error),
                  title: AppText('Limpar dados', fontWeight: FontWeight.w600, color: AppColors.error),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => Get.to(() => const ClearDataPage(), binding: SettingsBinding()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader('Preferências'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(LucideIcons.palette, color: AppColors.textSecondary(isDark)),
              title: AppText('Tema', fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDark)),
              subtitle: AppText.subtitle('Automático (do sistema)', color: AppColors.textSecondary(isDark)),
              trailing: AppText.subtitle('Em breve', color: AppColors.textSecondary(isDark)),
              onTap: () => Get.snackbar('Em breve', 'Este recurso ainda não está disponível.'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader('Sobre'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.info),
                  title: const AppText('Versão', fontWeight: FontWeight.w600),
                  trailing: FutureBuilder<PackageInfo>(
                    future: _packageInfoFuture,
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      final label = info == null ? '...' : '${info.version}+${info.buildNumber}';
                      return AppText.subtitle(label, color: AppColors.textSecondary(isDark));
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.scrollText),
                  title: const AppText('Licenças', fontWeight: FontWeight.w600),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => showLicensePage(context: context, applicationName: 'Buy Control'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppText.subtitle(label.toUpperCase(), color: AppColors.textSecondary(isDark));
  }
}
