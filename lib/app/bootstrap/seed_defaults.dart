import 'package:get/get.dart';
import 'package:buy_control/core/catalog/default_catalogs.dart';
import 'package:buy_control/core/database/app_meta_store.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

/// Semeia categorias, tipos de produto e unidades padrão na primeira
/// execução do app, com os nomes no idioma em uso (as abreviações das
/// unidades não mudam). Não roda de novo mesmo que o usuário apague tudo
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

  Future<void> run() async {
    if (metaStore.defaultsSeeded) return;

    final now = DateTime.now();

    for (final (abbreviation, name) in DefaultCatalogs.units) {
      final allowsDecimal = abbreviation == 'KG' || abbreviation == 'G' || abbreviation == 'L' || abbreviation == 'ML';
      await unitRepository.create(UnitEntity(
        id: IdGenerator.generate(),
        name: name.tr,
        abbreviation: abbreviation,
        allowsDecimal: allowsDecimal,
        createdAt: now,
        updatedAt: now,
      ));
    }

    for (final name in DefaultCatalogs.categories) {
      await categoryRepository.create(CategoryEntity(
        id: IdGenerator.generate(),
        name: name.tr,
        createdAt: now,
        updatedAt: now,
      ));
    }

    for (final name in DefaultCatalogs.productTypes) {
      await productTypeRepository.create(ProductTypeEntity(
        id: IdGenerator.generate(),
        name: name.tr,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await metaStore.setDefaultsSeeded(true);
  }
}
