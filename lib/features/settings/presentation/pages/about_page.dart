import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Configurações → Sobre o sistema: o que o app faz, como os dados são
/// guardados e as informações da versão instalada.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  static const appName = 'Buy Control';

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  static const _features = [
    (LucideIcons.package, 'Caixas', 'Agrupe as compras por contexto, como "Mercado" ou "Farmácia".'),
    (
      LucideIcons.scanBarcode,
      'Lançamentos',
      'Registre compras item a item, com leitura de código de barras, etiqueta de balança e promoções.',
    ),
    (
      LucideIcons.archive,
      'Fechamentos',
      'Feche o ciclo de uma caixa e guarde o histórico; lançamentos recorrentes seguem para o próximo.',
    ),
    (
      LucideIcons.squareKanban,
      'Planejamento',
      'Monte quadros de compras futuras com data de previsão e meta de gasto.',
    ),
    (
      LucideIcons.chartBar,
      'Relatórios',
      'Compare períodos, acompanhe gasto realizado e previsto e exporte em PDF ou CSV.',
    ),
    (LucideIcons.shoppingBasket, 'Catálogo', 'Produtos, categorias, tipos e unidades reutilizáveis.'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o sistema')),
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
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(LucideIcons.shoppingCart, size: 36, color: colors.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(AboutPage.appName, textAlign: TextAlign.center, style: text.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Planejamento e previsão de gastos',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(child: Chip(label: Text('Versão $version'))),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'O que o app faz',
                children: [
                  for (final (icon, title, description) in _features)
                    ListTile(
                      leading: Icon(icon, color: colors.primary),
                      title: Text(title),
                      subtitle: Text(description),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _Section(
                title: 'Seus dados',
                children: [
                  ListTile(
                    leading: Icon(LucideIcons.hardDrive),
                    title: Text('Guardados no aparelho'),
                    subtitle: Text('Tudo fica salvo localmente e o app funciona sem internet.'),
                  ),
                  ListTile(
                    leading: Icon(LucideIcons.databaseBackup),
                    title: Text('Backup manual'),
                    subtitle: Text('Use Configurações → Exportar dados para guardar uma cópia em arquivo.'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'Informações',
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.tag),
                    title: const Text('Versão'),
                    trailing: Text(version, style: text.bodyMedium),
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.hash),
                    title: const Text('Compilação'),
                    trailing: Text(build, style: text.bodyMedium),
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.scrollText),
                    title: const Text('Licenças de código aberto'),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: AboutPage.appName,
                      applicationVersion: version,
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
