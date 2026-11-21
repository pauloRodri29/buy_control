import 'package:get/get.dart';
import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/brand/app_logo.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/features/settings/presentation/pages/licenses_page.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Configurações → Sobre o sistema: o que o app faz, como os dados são
/// guardados e as informações da versão instalada.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  static const appName = AppBrand.name;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  static const _features = [
    (Symbols.inventory_2, 'common.boxes2', 'settings.groupPurchasesContextLikeGrocery'),
    (
      Symbols.qr_code_scanner,
      'common.entries',
      'settings.recordPurchasesItemItemBarcode',
    ),
    (
      Symbols.archive,
      'common.closings',
      'settings.closeBoxsCycleKeepHistory',
    ),
    (
      Symbols.view_kanban,
      'common.planning',
      'settings.buildBoardsFuturePurchasesPlanned',
    ),
    (
      Symbols.bar_chart,
      'common.reports',
      'settings.comparePeriodsTrackActualPlanned',
    ),
    (Symbols.shopping_basket, 'settings.catalog', 'settings.reusableProductsCategoriesTypesUnits'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Scaffold(
      appBar: AppBar(title: Text('settings.aboutApp'.tr)),
      body: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final info = snapshot.data;
          final version = info == null ? '...' : info.version;
          final build = info == null ? '...' : info.buildNumber;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.md),
              const Center(child: AppLogo()),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppBrand.description,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(child: Chip(label: Text('settings.version2'.trParams({'version': version})))),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'settings.whatAppDoes'.tr,
                children: [
                  for (final (icon, title, description) in _features)
                    ListTile(
                      leading: Icon(icon, color: colors.primary),
                      title: Text(title.tr),
                      subtitle: Text(description.tr),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'settings.data2'.tr,
                children: [
                  ListTile(
                    leading: Icon(Symbols.storage),
                    title: Text('settings.storedDevice'.tr),
                    subtitle: Text('settings.everythingSavedLocallyAppWorks'.tr),
                  ),
                  ListTile(
                    leading: Icon(Symbols.backup),
                    title: Text('common.manualBackup'.tr),
                    subtitle: Text('settings.useSettingsBackupRestoreKeep'.tr),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'settings.information'.tr,
                children: [
                  ListTile(
                    leading: const Icon(Symbols.sell),
                    title: Text('settings.version'.tr),
                    trailing: Text(version, style: text.bodyMedium),
                  ),
                  ListTile(
                    leading: const Icon(Symbols.tag),
                    title: Text('settings.build'.tr),
                    trailing: Text(build, style: text.bodyMedium),
                  ),
                  ListTile(
                    leading: const Icon(Symbols.receipt_long),
                    title: Text('settings.openSourceLicenses'.tr),
                    trailing: const Icon(Symbols.chevron_right, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LicensesPage(
                          applicationName: AboutPage.appName,
                          applicationVersion: version,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

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
