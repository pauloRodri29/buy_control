import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Configurações → Sobre o sistema → Licenças de código aberto.
///
/// Substitui o `showLicensePage` nativo, que tem textos fixos em inglês
/// ("Powered by Flutter"). Lê as mesmas licenças do [LicenseRegistry].
class LicensesPage extends StatefulWidget {
  final String applicationName;
  final String applicationVersion;

  const LicensesPage({super.key, required this.applicationName, required this.applicationVersion});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  late final Future<Map<String, List<LicenseEntry>>> _licenses = _load();

  static Future<Map<String, List<LicenseEntry>>> _load() async {
    final byPackage = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        byPackage.putIfAbsent(package, () => []).add(entry);
      }
    }
    final names = byPackage.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final name in names) name: byPackage[name]!};
  }

  static String _countLabel(int count) => count == 1 ? '1 licença' : '$count licenças';

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Licenças')),
      body: FutureBuilder<Map<String, List<LicenseEntry>>>(
        future: _licenses,
        builder: (context, snapshot) {
          final header = [
            const SizedBox(height: AppSpacing.xl),
            Text(widget.applicationName, textAlign: TextAlign.center, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Versão ${widget.applicationVersion}',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Desenvolvido com Flutter',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
          ];

          if (snapshot.hasError) {
            return ListView(
              children: [
                ...header,
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('Não foi possível carregar as licenças.', textAlign: TextAlign.center),
                ),
              ],
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return ListView(
              children: [...header, const Center(child: CircularProgressIndicator())],
            );
          }

          final names = data.keys.toList();
          return ListView.builder(
            itemCount: header.length + names.length,
            itemBuilder: (context, index) {
              if (index < header.length) return header[index];
              final name = names[index - header.length];
              final entries = data[name]!;
              return ListTile(
                title: Text(name),
                subtitle: Text(_countLabel(entries.length)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _PackageLicensesPage(packageName: name, entries: entries),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PackageLicensesPage extends StatelessWidget {
  final String packageName;
  final List<LicenseEntry> entries;

  const _PackageLicensesPage({required this.packageName, required this.entries});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;

    final children = <Widget>[
      Card(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        color: colors.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'As licenças são documentos jurídicos publicados pelos autores de cada '
                  'pacote e só têm validade no idioma original (geralmente inglês). '
                  'Por isso, o texto completo é exibido como foi publicado, com um resumo '
                  'em português quando a licença é conhecida.',
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    for (var i = 0; i < entries.length; i++) {
      final paragraphs = entries[i].paragraphs.toList();
      final summary = _LicenseSummary.detect(paragraphs.map((p) => p.text).join('\n'));

      children.add(SizedBox(height: i == 0 ? AppSpacing.lg : AppSpacing.xxl));
      if (entries.length > 1) {
        children.add(Text('Licença ${i + 1} de ${entries.length}', style: text.titleSmall));
        children.add(const SizedBox(height: AppSpacing.sm));
      }
      if (summary != null) {
        children.add(
          Card(
            margin: EdgeInsets.zero,
            color: colors.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo em português — ${summary.name}',
                    style: text.titleSmall?.copyWith(color: colors.onSecondaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    summary.description,
                    style: text.bodyMedium?.copyWith(color: colors.onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ),
        );
        children.add(const SizedBox(height: AppSpacing.md));
      }
      children.add(
        Text(
          'Texto original',
          style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
      for (final paragraph in paragraphs) {
        final centered = paragraph.indent == LicenseParagraph.centeredIndent;
        final indent = centered ? 0 : paragraph.indent;
        children.add(
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.lg * indent),
            child: Text(
              paragraph.text,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: centered ? text.bodyMedium?.copyWith(fontWeight: FontWeight.bold) : text.bodyMedium,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(packageName),
            Text(
              entries.length == 1 ? '1 licença' : '${entries.length} licenças',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          children: children,
        ),
      ),
    );
  }
}

/// Resumo em português das licenças de código aberto mais comuns,
/// reconhecidas por trechos característicos do texto original.
class _LicenseSummary {
  final String name;
  final String description;

  const _LicenseSummary(this.name, this.description);

  static _LicenseSummary? detect(String original) {
    final t = original.toLowerCase();
    if (t.contains('apache license') && t.contains('version 2.0')) return _apache2;
    if (t.contains('mozilla public license')) return _mpl2;
    if (t.contains('gnu lesser general public license')) return _lgpl;
    if (t.contains('gnu general public license')) return _gpl;
    if (t.contains('permission is hereby granted, free of charge')) return _mit;
    if (t.contains('redistribution and use in source and binary forms')) {
      return t.contains('neither the name') || t.contains('may not be used to endorse') ? _bsd3 : _bsd2;
    }
    if (t.contains('permission to use, copy, modify, and/or distribute') ||
        t.contains('permission to use, copy, modify, and distribute')) {
      return _isc;
    }
    if (t.contains("provided 'as-is'") && t.contains('altered source versions')) return _zlib;
    if (t.contains('unicode') && t.contains('data files')) return _unicode;
    if (t.contains('freetype project')) return _freetype;
    if (t.contains('sil open font license')) return _ofl;
    return null;
  }

  static const _semGarantia =
      'O software é fornecido "no estado em que se encontra", sem garantias de nenhum tipo, '
      'e os autores não se responsabilizam por danos decorrentes do seu uso.';

  static const _apache2 = _LicenseSummary(
    'Licença Apache 2.0',
    'Permite usar, copiar, modificar e distribuir o software, inclusive em produtos comerciais. '
        'Quem redistribuir deve incluir uma cópia desta licença, manter os avisos de direitos '
        'autorais e o arquivo NOTICE (se existir) e indicar os arquivos que modificou. '
        'Também concede licença de uso das patentes dos colaboradores, que é revogada de quem '
        'mover processo por violação de patente relacionada ao software. $_semGarantia',
  );

  static const _mit = _LicenseSummary(
    'Licença MIT',
    'Permite, gratuitamente, usar, copiar, modificar, mesclar, publicar, distribuir, '
        'sublicenciar e vender cópias do software, desde que o aviso de direitos autorais e '
        'esta permissão sejam incluídos em todas as cópias ou partes substanciais. $_semGarantia',
  );

  static const _bsd3 = _LicenseSummary(
    'Licença BSD de 3 cláusulas',
    'Permite redistribuir e usar o software, com ou sem modificações, em código-fonte ou '
        'binário, desde que: (1) o código-fonte mantenha o aviso de direitos autorais, esta '
        'lista de condições e o aviso de isenção; (2) as distribuições binárias reproduzam '
        'esses avisos na documentação; e (3) o nome dos autores não seja usado para promover '
        'produtos derivados sem permissão por escrito. $_semGarantia',
  );

  static const _bsd2 = _LicenseSummary(
    'Licença BSD de 2 cláusulas',
    'Permite redistribuir e usar o software, com ou sem modificações, em código-fonte ou '
        'binário, desde que o aviso de direitos autorais, esta lista de condições e o aviso '
        'de isenção sejam mantidos no código-fonte e reproduzidos na documentação das '
        'distribuições binárias. $_semGarantia',
  );

  static const _isc = _LicenseSummary(
    'Licença ISC',
    'Permite usar, copiar, modificar e distribuir o software para qualquer finalidade, com '
        'ou sem cobrança, desde que o aviso de direitos autorais e esta permissão apareçam em '
        'todas as cópias. $_semGarantia',
  );

  static const _zlib = _LicenseSummary(
    'Licença zlib',
    'Permite usar o software para qualquer finalidade, inclusive comercial, e alterá-lo e '
        'redistribuí-lo livremente, desde que: a origem não seja deturpada (não se pode alegar '
        'ter escrito o software original); versões alteradas sejam identificadas como tal; e '
        'este aviso não seja removido das distribuições do código-fonte. $_semGarantia',
  );

  static const _mpl2 = _LicenseSummary(
    'Mozilla Public License 2.0',
    'Permite usar, modificar e distribuir o software, inclusive junto com código de outras '
        'licenças. Os arquivos cobertos por esta licença que forem modificados devem continuar '
        'sob a MPL e ter o código-fonte disponibilizado; o restante do projeto pode usar outra '
        'licença. $_semGarantia',
  );

  static const _lgpl = _LicenseSummary(
    'GNU LGPL',
    'Permite usar a biblioteca, inclusive em software proprietário, desde que ela possa ser '
        'substituída por outra versão pelo usuário. Modificações feitas na própria biblioteca '
        'devem ser distribuídas sob a mesma licença, com o código-fonte disponível. $_semGarantia',
  );

  static const _gpl = _LicenseSummary(
    'GNU GPL',
    'Permite usar, estudar, modificar e distribuir o software. Quem distribuir o software ou '
        'trabalhos derivados deve fazê-lo sob a mesma licença e disponibilizar o código-fonte '
        'correspondente. $_semGarantia',
  );

  static const _unicode = _LicenseSummary(
    'Licença Unicode',
    'Permite usar, copiar, modificar e distribuir os arquivos de dados e o software Unicode, '
        'desde que o aviso de direitos autorais e esta permissão acompanhem todas as cópias ou '
        'a documentação. $_semGarantia',
  );

  static const _freetype = _LicenseSummary(
    'Licença FreeType',
    'Permite usar, modificar e distribuir o FreeType, inclusive em produtos comerciais, desde '
        'que a documentação mencione o uso do FreeType e os avisos de direitos autorais sejam '
        'mantidos no código-fonte. $_semGarantia',
  );

  static const _ofl = _LicenseSummary(
    'SIL Open Font License',
    'Permite usar, estudar, modificar e redistribuir a fonte, inclusive embutida em software. '
        'A fonte não pode ser vendida sozinha, e versões modificadas devem usar outro nome e '
        'continuar sob a mesma licença. $_semGarantia',
  );
}
