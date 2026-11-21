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
    (Symbols.inventory_2, 'Caixas', 'Agrupe as compras por contexto, como "Mercado" ou "Farmácia".'),
    (
      Symbols.qr_code_scanner,
      'Lançamentos',
      'Registre compras item a item, com leitura de código de barras, etiqueta de balança e promoções.',
    ),
    (
      Symbols.archive,
      'Fechamentos',
      'Feche o ciclo de uma caixa e guarde o histórico; lançamentos recorrentes seguem para o próximo.',
    ),
    (
      Symbols.view_kanban,
      'Planejamento',
      'Monte quadros de compras futuras com data de previsão e meta de gasto.',
    ),
    (
      Symbols.bar_chart,
      'Relatórios',
      'Compare períodos, acompanhe gasto realizado e previsto e exporte em PDF.',
    ),
    (Symbols.shopping_basket, 'Catálogo', 'Produtos, categorias, tipos e unidades reutilizáveis.'),
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
              const Center(child: AppLogo()),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppBrand.description,
                textAlign: TextAlign.center,
                style: text.bodySmall,
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
                    leading: Icon(Symbols.storage),
                    title: Text('Guardados no aparelho'),
                    subtitle: Text('Tudo fica salvo localmente e o app funciona sem internet.'),
                  ),
                  ListTile(
                    leading: Icon(Symbols.backup),
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
                    leading: const Icon(Symbols.sell),
                    title: const Text('Versão'),
                    trailing: Text(version, style: text.bodyMedium),
                  ),
                  ListTile(
                    leading: const Icon(Symbols.tag),
                    title: const Text('Compilação'),
                    trailing: Text(build, style: text.bodyMedium),
                  ),
                  ListTile(
                    leading: const Icon(Symbols.receipt_long),
                    title: const Text('Licenças de código aberto'),
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
