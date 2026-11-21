import 'dart:io';
import 'dart:ui';

import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Garante que os JSON de `assets/i18n` acompanham o código: todos os
/// idiomas com as mesmas chaves e os mesmos `@parâmetros`, e toda chave
/// usada em `lib/` presente nos arquivos. Os textos já vêm carregados pelo
/// `test/flutter_test_config.dart`.
/// Literais no formato de chave que não são textos (ex.: chaves do Hive).
const _notTextKeys = {'backup.log'};

void main() {
  final placeholder = RegExp(r'@\w+');
  final maps = AppLocale.translationMaps;
  final reference = maps[AppLocale.source.toString()]!;

  test('cada idioma tem seu JSON carregado de assets/i18n', () {
    for (final language in AppLocale.languages) {
      expect(maps[language.code], isNotEmpty, reason: language.asset);
    }
  });

  test('todos os idiomas têm as mesmas chaves', () {
    for (final MapEntry(key: code, value: texts) in maps.entries) {
      expect(reference.keys.toSet().difference(texts.keys.toSet()), isEmpty, reason: 'faltando em $code');
      expect(texts.keys.toSet().difference(reference.keys.toSet()), isEmpty, reason: 'sobrando em $code');
    }
  });

  test('cada texto usa os mesmos parâmetros @nome que o português', () {
    final problems = <String>[];
    for (final MapEntry(key: code, value: texts) in maps.entries) {
      texts.forEach((key, value) {
        final expected = placeholder.allMatches(reference[key] ?? '').map((m) => m[0]).toSet();
        final actual = placeholder.allMatches(value).map((m) => m[0]).toSet();
        if (expected.length != actual.length || !expected.containsAll(actual)) {
          problems.add('$code: $key => $value');
        }
      });
    }
    expect(problems, isEmpty);
  });

  test('toda chave usada em lib/ existe nos JSON', () {
    final prefixes = {for (final key in reference.keys) key.split('.').first};
    final keyLiteral = RegExp(r"'([a-z][a-zA-Z]*)\.([a-zA-Z0-9]+)'");
    final found = <String>{};
    final missing = <String>{};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final m in keyLiteral.allMatches(file.readAsStringSync())) {
        final key = '${m[1]}.${m[2]}';
        if (!prefixes.contains(m[1]) || _notTextKeys.contains(key)) continue;
        found.add(key);
        if (!reference.containsKey(key)) missing.add('${file.path}: $key');
      }
    }
    // Proteção contra a varredura parar de encontrar chaves sem ninguém notar.
    expect(found.length, greaterThan(700));
    expect(missing, isEmpty, reason: 'Adicione as chaves em todos os JSON de assets/i18n/');
  });

  group('troca de idioma', () {
    tearDown(() => Get.locale = AppLocale.ptBR);

    test('cada idioma lê o próprio arquivo', () {
      Get.locale = AppLocale.enUS;
      expect('common.save'.tr, 'Save');
      expect('common.planName'.trParams({'name': 'Pro'}), 'Pro plan');

      Get.locale = AppLocale.ptBR;
      expect('common.save'.tr, 'Salvar');
      expect('common.planName'.trParams({'name': 'Pro'}), 'Plano Pro');
    });

    test('idioma inicial segue o aparelho: português ou, senão, inglês', () {
      expect(AppLocale.fromDevice(const Locale('pt', 'PT')), AppLocale.ptBR);
      expect(AppLocale.fromDevice(const Locale('es', 'ES')), AppLocale.enUS);
      expect(AppLocale.fromDevice(null), AppLocale.enUS);
    });
  });
}
