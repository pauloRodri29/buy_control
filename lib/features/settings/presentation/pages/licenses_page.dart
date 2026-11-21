import 'package:get/get.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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

  static String _countLabel(int count) => count == 1 ? 'settings.n1License'.tr : 'settings.licensesCount'.trParams({'count': '$count'});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text('settings.licenses'.tr)),
      body: FutureBuilder<Map<String, List<LicenseEntry>>>(
        future: _licenses,
        builder: (context, snapshot) {
          final header = [
            const SizedBox(height: AppSpacing.xl),
            Text(widget.applicationName, textAlign: TextAlign.center, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'settings.versionApplicationVersion'.trParams({'applicationVersion': widget.applicationVersion}),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'settings.builtFlutter'.tr,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
          ];

          if (snapshot.hasError) {
            return ListView(
              children: [
                ...header,
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('settings.couldntLoadLicenses'.tr, textAlign: TextAlign.center),
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
              Icon(Symbols.info, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'settings.licensesAreLegalDocumentsPublished'.tr,
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
        children.add(Text('settings.licenseValueCount'.trParams({'value': '${i + 1}', 'length': '${entries.length}'}), style: text.titleSmall));
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
                    'settings.summaryName'.trParams({'name': summary.name.tr}),
                    style: text.titleSmall?.copyWith(color: colors.onSecondaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    summary.text,
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
          'settings.originalText'.tr,
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
              entries.length == 1 ? 'settings.n1License'.tr : 'settings.licensesCount2'.trParams({'length': '${entries.length}'}),
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

  /// Resumo no idioma atual, sempre com o aviso de "sem garantia".
  String get text => '${description.tr} ${_semGarantia.tr}';

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
      'settings.softwareProvidedWithoutWarrantyAny';

  static const _apache2 = _LicenseSummary(
    'settings.apacheLicense20',
    'settings.allowsUsingCopyingModifyingDistributing2',
  );

  static const _mit = _LicenseSummary(
    'settings.mitLicense',
    'settings.allowsFreeChargeUsingCopying',
  );

  static const _bsd3 = _LicenseSummary(
    'settings.n3ClauseBsdLicense',
    'settings.allowsRedistributionUseSoftwareWithout2',
  );

  static const _bsd2 = _LicenseSummary(
    'settings.n2ClauseBsdLicense',
    'settings.allowsRedistributionUseSoftwareWithout',
  );

  static const _isc = _LicenseSummary(
    'settings.iscLicense',
    'settings.allowsUsingCopyingModifyingDistributing',
  );

  static const _zlib = _LicenseSummary(
    'settings.zlibLicense',
    'settings.allowsUsingSoftwareAnyPurpose',
  );

  static const _mpl2 = _LicenseSummary(
    'settings.mozillaPublicLicense20',
    'settings.allowsUsingModifyingDistributingSoftware',
  );

  static const _lgpl = _LicenseSummary(
    'settings.gnuLgpl',
    'settings.allowsUsingLibraryIncludingProprietary',
  );

  static const _gpl = _LicenseSummary(
    'settings.gnuGpl',
    'settings.allowsUsingStudyingModifyingDistributing',
  );

  static const _unicode = _LicenseSummary(
    'settings.unicodeLicense',
    'settings.allowsUsingCopyingModifyingDistributing3',
  );

  static const _freetype = _LicenseSummary(
    'settings.freetypeLicense',
    'settings.allowsUsingModifyingDistributingFreetype',
  );

  static const _ofl = _LicenseSummary(
    'settings.silOpenFontLicense',
    'settings.allowsUsingStudyingModifyingRedistributing',
  );
}
