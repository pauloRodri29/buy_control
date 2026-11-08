import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/auth/presentation/pages/profile_page.dart';
import 'package:buy_control/features/backup/presentation/backup_actions.dart';
import 'package:buy_control/features/settings/presentation/bindings/settings_binding.dart';
import 'package:buy_control/features/settings/presentation/pages/clear_data_page.dart';
import 'package:buy_control/features/settings/presentation/widgets/theme_mode_sheet.dart';
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
    const chevron = Icon(LucideIcons.chevronRight, size: 18);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(
            title: 'Conta',
            children: [
              _Tile(
                icon: LucideIcons.userCircle,
                title: 'Perfil',
                trailing: chevron,
                onTap: () => Get.to(() => const ProfilePage()),
              ),
              _Tile(icon: LucideIcons.logOut, title: 'Sair', onTap: () => _logout(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _Section(
            title: 'Dados',
            children: [
              _Tile(
                icon: LucideIcons.uploadCloud,
                title: 'Exportar dados',
                trailing: chevron,
                onTap: () => runExportBackup(context),
              ),
              _Tile(
                icon: LucideIcons.downloadCloud,
                title: 'Importar dados',
                trailing: chevron,
                onTap: () => runImportBackup(context),
              ),
              _Tile(
                icon: LucideIcons.trash2,
                title: 'Limpar dados',
                destructive: true,
                trailing: chevron,
                onTap: () => Get.to(() => const ClearDataPage(), binding: SettingsBinding()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GetBuilder<ThemeController>(
            builder: (themeController) => _Section(
              title: 'Preferências',
              children: [
                _Tile(
                  icon: LucideIcons.palette,
                  title: 'Tema',
                  subtitle: themeController.mode.label,
                  trailing: chevron,
                  onTap: () => AppBottomSheet.show(context, child: const ThemeModeSheet()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Section(
            title: 'Sobre',
            children: [
              _Tile(
                icon: LucideIcons.info,
                title: 'Versão',
                trailing: FutureBuilder<PackageInfo>(
                  future: _packageInfoFuture,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    return Text(info == null ? '...' : '${info.version}+${info.buildNumber}');
                  },
                ),
              ),
              _Tile(
                icon: LucideIcons.scrollText,
                title: 'Licenças',
                trailing: chevron,
                onTap: () => showLicensePage(context: context, applicationName: 'Buy Control'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grupo de opções: título em caixa alta e um [Card] com os itens
/// separados por divisória.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: context.text.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.colors.error : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
