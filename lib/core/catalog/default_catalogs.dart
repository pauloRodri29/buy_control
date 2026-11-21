import 'package:buy_control/core/i18n/app_locale.dart';

/// Catálogos padrão semeados na primeira execução (`SeedDefaults`).
///
/// Também servem para separar o que veio do app do que o usuário criou:
/// os itens padrão nunca contam na cota do plano nem ficam bloqueados.
class DefaultCatalogs {
  DefaultCatalogs._();

  /// (abreviação, chave do nome em assets/i18n). Os nomes de [categories]
  /// e [productTypes] também são chaves.
  static const units = [
    ('UN', 'common.unit'),
    ('PCT', 'catalog.pack'),
    ('CX', 'catalog.box'),
    ('FD', 'catalog.bundle'),
    ('KG', 'catalog.kilogramKg'),
    ('G', 'catalog.gramG'),
    ('L', 'catalog.literL'),
    ('ML', 'catalog.milliliterMl'),
    ('FR', 'catalog.bottle'),
    ('PT', 'catalog.jar'),
    ('TB', 'catalog.tube'),
    ('BDJ', 'catalog.tray'),
    ('DZ', 'catalog.dozen'),
    ('KIT', 'catalog.kit'),
  ];

  static const categories = [
    'catalog.food',
    'catalog.cleaning',
    'catalog.home',
    'catalog.clothing',
    'catalog.subscriptions',
    'catalog.transportation',
    'catalog.leisure',
    'catalog.health',
    'catalog.work',
    'common.other',
  ];

  static const productTypes = [
    'catalog.food2',
    'catalog.beverage',
    'catalog.personalCare',
    'catalog.cleaning',
    'catalog.clothing',
    'catalog.electronics',
    'catalog.constructionMaterial',
    'catalog.schoolSupplies',
    'catalog.service',
    'common.subscription',
    'catalog.transportation',
    'catalog.medicine',
    'catalog.householdItem',
    'common.other',
  ];

  // Os padrões são semeados no idioma da primeira execução, então valem
  // os nomes em todos os idiomas do app. Calculados na hora (não em
  // `static final`): dependem dos textos carregados de assets/i18n.
  static Set<String> get _categoryKeys => {for (final c in categories) ..._keysOf(c)};
  static Set<String> get _productTypeKeys => {for (final t in productTypes) ..._keysOf(t)};
  static final _unitKeys = {for (final (abbreviation, _) in units) _key(abbreviation)};

  static String _key(String value) => value.trim().toLowerCase();

  /// Nome do item padrão em cada idioma, a partir da chave de assets/i18n.
  static List<String> _keysOf(String key) => [
        for (final texts in AppLocale.translationMaps.values) _key(texts[key] ?? key),
      ];

  static bool isDefaultCategory(String name) => _categoryKeys.contains(_key(name));
  static bool isDefaultProductType(String name) => _productTypeKeys.contains(_key(name));
  static bool isDefaultUnit(String abbreviation) => _unitKeys.contains(_key(abbreviation));
}
