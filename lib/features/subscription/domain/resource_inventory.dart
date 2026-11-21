import 'package:buy_control/core/catalog/default_catalogs.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_item_positions.dart';
import 'package:buy_control/features/product_types/domain/repositories/product_type_repository.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/units/domain/repositories/unit_repository.dart';

/// Um registro que conta (ou não) na cota de um recurso.
class ResourceItem {
  final String id;

  /// Ordem de prioridade: os primeiros ficam liberados quando o plano
  /// diminui. Data de criação, ou a posição na coluna (itens de quadro).
  final Comparable<Object> order;

  /// Itens padrão do app: nunca contam nem ficam bloqueados.
  final bool exempt;

  /// Para limites por "pai" (itens por quadro): o quadro do item.
  final String? group;

  const ResourceItem({required this.id, required this.order, this.exempt = false, this.group});
}

/// Lista, para cada recurso, o que conta na cota do plano.
///
/// Regras:
/// - excluídos não contam; Boxes e quadros arquivados contam;
/// - categorias, tipos e unidades padrão não contam;
/// - quadros: só os abertos (finalizados e cancelados não contam);
/// - itens por quadro: os itens de cada coluna aberta, sem as Pendências.
class ResourceInventory {
  final BoxRepository boxRepository;
  final ProductRepository productRepository;
  final CategoryRepository categoryRepository;
  final ProductTypeRepository productTypeRepository;
  final UnitRepository unitRepository;
  final PlanBoardRepository planBoardRepository;
  final PlanItemRepository planItemRepository;

  const ResourceInventory({
    required this.boxRepository,
    required this.productRepository,
    required this.categoryRepository,
    required this.productTypeRepository,
    required this.unitRepository,
    required this.planBoardRepository,
    required this.planItemRepository,
  });

  Future<Result<List<ResourceItem>>> items(ResourceKey resource) async {
    switch (resource) {
      case ResourceKey.boxes:
        return _map(await boxRepository.getAll(includeArchived: true),
            (b) => ResourceItem(id: b.id, order: b.createdAt));
      case ResourceKey.products:
        return _map(await productRepository.getAll(),
            (p) => ResourceItem(id: p.id, order: p.createdAt));
      case ResourceKey.categories:
        return _map(
          await categoryRepository.getAll(),
          (c) => ResourceItem(id: c.id, order: c.createdAt, exempt: DefaultCatalogs.isDefaultCategory(c.name)),
        );
      case ResourceKey.productTypes:
        return _map(
          await productTypeRepository.getAll(),
          (t) => ResourceItem(id: t.id, order: t.createdAt, exempt: DefaultCatalogs.isDefaultProductType(t.name)),
        );
      case ResourceKey.units:
        return _map(
          await unitRepository.getAll(),
          (u) => ResourceItem(id: u.id, order: u.createdAt, exempt: DefaultCatalogs.isDefaultUnit(u.abbreviation)),
        );
      case ResourceKey.planBoards:
        final boards = await planBoardRepository.getAll(includeArchived: true);
        return _map(boards, (b) => b.isOpen ? ResourceItem(id: b.id, order: b.createdAt) : null);
      case ResourceKey.planItemsPerBoard:
        return _planItems();
    }
  }

  Future<Result<List<ResourceItem>>> _planItems() async {
    final boardsResult = await planBoardRepository.getAll(includeArchived: true);
    if (boardsResult case Failure(:final failure)) return Failure(failure);
    final itemsResult = await planItemRepository.getAll();
    if (itemsResult case Failure(:final failure)) return Failure(failure);

    final items = itemsResult.dataOrNull!;
    final openBoardIds = <String?>[
      null, // "Sem quadro"
      for (final b in boardsResult.dataOrNull!)
        if (b.isOpen) b.id,
    ];
    return Success([
      for (final boardId in openBoardIds)
        for (final item in PlanItemPositions.column(items, boardId))
          ResourceItem(id: item.id, order: item.position, group: boardId),
    ]);
  }

  Result<List<ResourceItem>> _map<T>(Result<List<T>> result, ResourceItem? Function(T) toItem) {
    return result.fold(
      (data) => Success([
        for (final entity in data)
          if (toItem(entity) case final item?) item,
      ]),
      (failure) => Failure(failure),
    );
  }
}
