import 'package:buy_control/app/i18n/locale_controller.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/auth/presentation/pages/profile_page.dart';
import 'package:buy_control/features/backup/presentation/bindings/backup_binding.dart';
import 'package:buy_control/features/backup/presentation/pages/backup_page.dart';
import 'package:buy_control/features/settings/presentation/bindings/settings_binding.dart';
import 'package:buy_control/features/settings/presentation/pages/about_page.dart';
import 'package:buy_control/features/settings/presentation/pages/clear_data_page.dart';
import 'package:buy_control/features/settings/presentation/widgets/language_sheet.dart';
import 'package:buy_control/features/settings/presentation/widgets/theme_mode_sheet.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:buy_control/features/subscription/presentation/pages/my_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';
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
      title: 'common.signOutAccount'.tr,
      message: 'settings.youllNeedSignAgainAccess'.tr,
      confirmLabel: 'common.signOut'.tr,
    );
    if (confirmed) await Get.find<AuthController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    const chevron = Icon(Symbols.chevron_right, size: 18);

    return Scaffold(
      appBar: AppBar(title: Text('common.settings'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(
            title: 'settings.account'.tr,
            children: [
              _Tile(
                icon: Symbols.account_circle,
                title: 'common.profile'.tr,
                trailing: chevron,
                onTap: () => Get.to(() => const ProfilePage()),
              ),
              GetBuilder<SubscriptionController>(
                builder: (subscription) => _Tile(
                  icon: Symbols.workspace_premium,
                  title: 'common.myPlan'.tr,
                  subtitle: 'common.planName'.trParams({'name': subscription.plan.name}),
                  trailing: chevron,
                  onTap: () => Get.to(() => const MyPlanPage()),
                ),
              ),
              _Tile(icon: Symbols.logout, title: 'common.signOut'.tr, onTap: () => _logout(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _Section(
            title: 'settings.data'.tr,
            children: [
              _Tile(
                icon: Symbols.cloud_sync,
                title: 'common.backupRestore'.tr,
                subtitle: 'settings.fileCloudGithub'.tr,
                trailing: chevron,
                onTap: () => Get.to(() => const BackupPage(), binding: BackupBinding()),
              ),
              _Tile(
                icon: Symbols.delete,
                title: 'settings.clearData'.tr,
                destructive: true,
                trailing: chevron,
                onTap: () => Get.to(() => const ClearDataPage(), binding: SettingsBinding()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GetBuilder<ThemeController>(
            builder: (themeController) => _Section(
              title: 'settings.preferences'.tr,
              children: [
                _Tile(
                  icon: Symbols.palette,
                  title: 'settings.theme'.tr,
                  subtitle: themeController.mode.label,
                  trailing: chevron,
                  onTap: () => AppBottomSheet.show(context, child: const ThemeModeSheet()),
                ),
                GetBuilder<LocaleController>(
                  builder: (localeController) => _Tile(
                    icon: Symbols.translate,
                    title: 'settings.language'.tr,
                    subtitle: AppLocale.nativeName(localeController.locale),
                    trailing: chevron,
                    onTap: () => AppBottomSheet.show(context, child: const LanguageSheet()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Section(
            title: 'settings.about'.tr,
            children: [
              FutureBuilder<PackageInfo>(
                future: _packageInfoFuture,
                builder: (context, snapshot) => _Tile(
                  icon: Symbols.info,
                  title: 'settings.aboutApp'.tr,
                  subtitle: snapshot.data == null ? null : 'settings.version2'.trParams({'version': snapshot.data!.version}),
                  trailing: chevron,
                  onTap: () => Get.to(() => const AboutPage()),
                ),
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
