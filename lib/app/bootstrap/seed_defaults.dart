import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

/// Semeia categorias, tipos de produto e unidades padrão na primeira
/// execução do app. Não roda de novo mesmo que o usuário apague tudo
/// manualmente depois (controlado pela flag `defaultsSeeded`).
class SeedDefaults {
  final AppMetaStore metaStore;
  final CategoryRepository categoryRepository;
  final ProductTypeRepository productTypeRepository;
  final UnitRepository unitRepository;

  const SeedDefaults({
    required this.metaStore,
    required this.categoryRepository,
    required this.productTypeRepository,
    required this.unitRepository,
  });

  static const _defaultUnits = [
    ('UN', 'Unidade'),
    ('PCT', 'Pacote'),
    ('CX', 'Caixa'),
    ('FD', 'Fardo'),
    ('KG', 'Quilo (kg)'),
    ('G', 'Grama (g)'),
    ('L', 'Litro (L)'),
    ('ML', 'Mililitro (ml)'),
    ('FR', 'Frasco'),
    ('PT', 'Pote'),
    ('TB', 'Tubo'),
    ('BDJ', 'Bandeja'),
    ('DZ', 'Dúzia'),
    ('KIT', 'Kit'),
  ];

  static const _defaultCategories = [
    'Alimentação',
    'Limpeza',
    'Casa',
    'Vestuário',
    'Assinaturas',
    'Transporte',
    'Lazer',
    'Saúde',
    'Trabalho',
    'Outros',
  ];

  static const _defaultProductTypes = [
    'Alimento',
    'Bebida',
    'Higiene',
    'Limpeza',
    'Vestuário',
    'Eletrônico',
    'Material de construção',
    'Material escolar',
    'Serviço',
    'Assinatura',
    'Transporte',
    'Medicamento',
    'Item doméstico',
    'Outros',
  ];

  Future<void> run() async {
    if (metaStore.defaultsSeeded) return;

    final now = DateTime.now();

    for (final (abbreviation, name) in _defaultUnits) {
      final allowsDecimal = abbreviation == 'KG' || abbreviation == 'G' || abbreviation == 'L' || abbreviation == 'ML';
      await unitRepository.create(UnitEntity(
        id: IdGenerator.generate(),
        name: name,
        abbreviation: abbreviation,
        allowsDecimal: allowsDecimal,
        createdAt: now,
        updatedAt: now,
      ));
    }

    for (final name in _defaultCategories) {
      await categoryRepository.create(CategoryEntity(
        id: IdGenerator.generate(),
        name: name,
        createdAt: now,
        updatedAt: now,
      ));
    }

    for (final name in _defaultProductTypes) {
      await productTypeRepository.create(ProductTypeEntity(
        id: IdGenerator.generate(),
        name: name,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await metaStore.setDefaultsSeeded(true);
  }
}
