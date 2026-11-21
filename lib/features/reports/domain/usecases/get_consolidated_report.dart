import 'package:get/get.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_board_repository.dart';
import 'package:buy_control/features/planning/domain/repositories/plan_item_repository.dart';
import 'package:buy_control/features/products/domain/repositories/product_repository.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class ReportEvolutionPoint {
  final DateTime month;
  final Money total;
  const ReportEvolutionPoint({required this.month, required this.total});
}

class ReportNamedTotal {
  final String id;
  final String name;
  final Money total;
  const ReportNamedTotal({required this.id, required this.name, required this.total});
}

class ReportProductCount {
  final String id;
  final String name;
  final double quantity;
  const ReportProductCount({required this.id, required this.name, required this.quantity});
}

class ReportProductLine {
  final String id;
  final String name;
  final double quantity;
  final Money total;
  const ReportProductLine({required this.id, required this.name, required this.quantity, required this.total});
}

/// Parte do relatório que vem do Planejamento.
///
/// - Realizado: itens marcados como comprados, contados no mês da data da
///   compra (já somados em [ConsolidatedReport.total]).
/// - Previsão: itens ainda pendentes e metas dos quadros cuja data de
///   previsão cai no período — o que ainda deve ser gasto.
class PlanningReportSummary {
  final Money purchasedTotal;
  final int purchasedCount;
  final List<ReportNamedTotal> purchasedByBoard;
  final Money forecastPending;
  final int pendingCount;
  final Money goalTotal;

  /// Soma de todos os itens (comprados ou não) dos quadros com previsão no
  /// período — é o que se compara com [goalTotal].
  final Money plannedInBoards;
  final int boardsInPeriod;

  const PlanningReportSummary({
    required this.purchasedTotal,
    required this.purchasedCount,
    required this.purchasedByBoard,
    required this.forecastPending,
    required this.pendingCount,
    required this.goalTotal,
    required this.plannedInBoards,
    required this.boardsInPeriod,
  });

  bool get isEmpty => purchasedCount == 0 && pendingCount == 0 && boardsInPeriod == 0;
}

class ConsolidatedReport {
  /// Total realizado: lançamentos das Boxes fechadas + compras do
  /// Planejamento marcadas como feitas no período.
  final Money total;
  final Money averagePerBox;
  final Money averagePerDay;
  final int transactionCount;
  final int itemCount;
  final ReportNamedTotal? topBox;
  final ReportNamedTotal? topCategory;
  final ReportProductCount? mostPurchasedProduct;
  final ReportNamedTotal? highestImpactProduct;
  final List<ReportEvolutionPoint> evolution;
  final List<ReportProductLine> productLines;

  /// `null` quando há filtros de Box/categoria/tipo/produto, que não se
  /// aplicam a itens do Planejamento.
  final PlanningReportSummary? planning;

  const ConsolidatedReport({
    required this.total,
    required this.averagePerBox,
    required this.averagePerDay,
    required this.transactionCount,
    required this.itemCount,
    this.topBox,
    this.topCategory,
    this.mostPurchasedProduct,
    this.highestImpactProduct,
    required this.evolution,
    this.productLines = const [],
    this.planning,
  });

  /// Total vindo só das Boxes (sem o Planejamento).
  Money get boxesTotal => total - (planning?.purchasedTotal ?? Money.zero);

  bool get isEmpty => transactionCount == 0 && (planning?.isEmpty ?? true);
}

/// Consolida lançamentos de uma ou mais Boxes (ou todas) dentro de um
/// período e conjunto de filtros, combinando dados que cada Box mantém
/// de forma independente — a combinação só acontece aqui, no módulo de
/// Relatórios, nunca nas Boxes em si.
class GetConsolidatedReport {
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final ProductRepository productRepository;

  /// Opcionais: sem eles o relatório considera só as Boxes.
  final PlanBoardRepository? planBoardRepository;
  final PlanItemRepository? planItemRepository;

  const GetConsolidatedReport({
    required this.boxRepository,
    required this.transactionRepository,
    required this.categoryRepository,
    required this.productRepository,
    this.planBoardRepository,
    this.planItemRepository,
  });

  Future<Result<ConsolidatedReport>> call({
    List<String> boxIds = const [],
    DateTime? start,
    DateTime? end,
    List<String> categoryIds = const [],
    List<String> productTypeIds = const [],
    List<String> productIds = const [],
    Money? minValue,
    Money? maxValue,
  }) async {
    final boxesResult = await boxRepository.getAll();
    if (boxesResult.isFailure) return Failure(boxesResult.failureOrNull!);
    final categoriesResult = await categoryRepository.getAll(includeInactive: true);
    if (categoriesResult.isFailure) return Failure(categoriesResult.failureOrNull!);
    final productsResult = await productRepository.getAll(includeInactive: true);
    if (productsResult.isFailure) return Failure(productsResult.failureOrNull!);
    final transactionsResult = await transactionRepository.getAll();
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    final boxNameById = {for (final b in boxesResult.dataOrNull!) b.id: b.name};
    final categoryNameById = {for (final c in categoriesResult.dataOrNull!) c.id: c.name};
    final productById = {for (final p in productsResult.dataOrNull!) p.id: p};

    // Relatórios consideram apenas lançamentos já congelados por um
    // Fechamento — nunca o estado atual (ainda editável) da Box. Isso
    // garante que um relatório emitido não mude silenciosamente depois.
    final closedTransactions = transactionsResult.dataOrNull!.where((t) => t.isClosed);

    final boxFiltered = closedTransactions.where((t) {
      if (boxIds.isNotEmpty && !boxIds.contains(t.boxId)) return false;
      if (start != null && t.accountingDate.isBefore(start)) return false;
      if (end != null && t.accountingDate.isAfter(end)) return false;
      if (minValue != null && t.total.cents < minValue.cents) return false;
      if (maxValue != null && t.total.cents > maxValue.cents) return false;
      return true;
    }).toList();

    bool itemMatches(TransactionItemEntity item) {
      if (categoryIds.isNotEmpty && !categoryIds.contains(item.categoryId)) return false;
      if (productIds.isNotEmpty && !productIds.contains(item.productId)) return false;
      if (productTypeIds.isNotEmpty) {
        // Tipo gravado no próprio item (inclusive avulso); itens antigos,
        // sem esse campo, caem no tipo atual do produto do catálogo.
        final typeId = item.productTypeId ??
            (item.productId == null ? null : productById[item.productId]?.productTypeId);
        if (typeId == null || !productTypeIds.contains(typeId)) return false;
      }
      return true;
    }

    final hasItemFilters = categoryIds.isNotEmpty || productIds.isNotEmpty || productTypeIds.isNotEmpty;

    var total = Money.zero;
    var itemCount = 0;
    var transactionCount = 0;
    final boxTotals = <String, int>{};
    final categoryTotals = <String, int>{};
    final productQuantities = <String, double>{};
    final productTotals = <String, int>{};
    final monthTotals = <DateTime, int>{};
    DateTime? earliest;
    DateTime? latest;

    void addToMonth(DateTime date, int cents) {
      final key = DateTime(date.year, date.month, 1);
      monthTotals[key] = (monthTotals[key] ?? 0) + cents;
      final currentFirst = earliest;
      final currentLast = latest;
      if (currentFirst == null || date.isBefore(currentFirst)) earliest = date;
      if (currentLast == null || date.isAfter(currentLast)) latest = date;
    }

    for (final t in boxFiltered) {
      final matchingItems = hasItemFilters ? t.items.where(itemMatches).toList() : t.items;
      if (hasItemFilters && matchingItems.isEmpty) continue;

      transactionCount++;
      final transactionMatchedTotal = matchingItems.fold(Money.zero, (sum, i) => sum + i.total);
      total += transactionMatchedTotal;
      itemCount += matchingItems.length;
      boxTotals[t.boxId] = (boxTotals[t.boxId] ?? 0) + transactionMatchedTotal.cents;
      addToMonth(t.accountingDate, transactionMatchedTotal.cents);

      for (final item in matchingItems) {
        final categoryKey = item.categoryId ?? 'sem_categoria';
        categoryTotals[categoryKey] = (categoryTotals[categoryKey] ?? 0) + item.total.cents;
        if (item.productId != null) {
          productQuantities[item.productId!] = (productQuantities[item.productId!] ?? 0) + item.quantity;
          productTotals[item.productId!] = (productTotals[item.productId!] ?? 0) + item.total.cents;
        }
      }
    }

    final distinctBoxCount = boxTotals.keys.length;
    final averagePerBox = distinctBoxCount == 0 ? Money.zero : Money((total.cents / distinctBoxCount).round());

    // Planejamento: filtros de Box/categoria/tipo/produto não se aplicam a
    // itens planejados, então com qualquer um deles ativo o relatório fica
    // restrito às Boxes.
    PlanningReportSummary? planning;
    final planBoards = planBoardRepository;
    final planItems = planItemRepository;
    if (planBoards != null && planItems != null && !hasItemFilters && boxIds.isEmpty) {
      final allBoardsResult = await planBoards.getAll(includeArchived: true);
      if (allBoardsResult.isFailure) return Failure(allBoardsResult.failureOrNull!);
      final allItemsResult = await planItems.getAll();
      if (allItemsResult.isFailure) return Failure(allItemsResult.failureOrNull!);

      final allBoards = allBoardsResult.dataOrNull!;
      final allItems = allItemsResult.dataOrNull!;
      final boardTitleById = {for (final b in allBoards) b.id: b.title};

      bool inPeriod(DateTime date) =>
          (start == null || !date.isBefore(start)) && (end == null || !date.isAfter(end));
      bool valueMatches(Money value) =>
          (minValue == null || value.cents >= minValue.cents) && (maxValue == null || value.cents <= maxValue.cents);

      var purchasedTotal = Money.zero;
      var purchasedCount = 0;
      final byBoard = <String, int>{};
      for (final item in allItems.where((i) => i.isPurchased)) {
        final date = item.purchasedAt ?? item.updatedAt;
        final value = item.value ?? Money.zero;
        if (!inPeriod(date) || !valueMatches(value)) continue;
        purchasedTotal += value;
        purchasedCount++;
        final boardKey = item.boardId ?? 'sem_quadro';
        byBoard[boardKey] = (byBoard[boardKey] ?? 0) + value.cents;
        addToMonth(date, value.cents);
      }

      final boardsInPeriod = allBoards.where((b) => inPeriod(b.targetDate)).toList();
      final boardIdsInPeriod = boardsInPeriod.map((b) => b.id).toSet();
      final pendingItems =
          allItems.where((i) => !i.isPurchased && boardIdsInPeriod.contains(i.boardId)).toList();

      total += purchasedTotal;
      itemCount += purchasedCount;

      planning = PlanningReportSummary(
        purchasedTotal: purchasedTotal,
        purchasedCount: purchasedCount,
        purchasedByBoard: byBoard.entries
            .map((e) => ReportNamedTotal(
                  id: e.key,
                  name: e.key == 'sem_quadro' ? 'common.noBoard'.tr : (boardTitleById[e.key] ?? 'reports.deletedBoard'.tr),
                  total: Money(e.value),
                ))
            .toList()
          ..sort((a, b) => b.total.cents.compareTo(a.total.cents)),
        forecastPending: pendingItems.fold(Money.zero, (sum, i) => sum + (i.estimatedValue ?? Money.zero)),
        pendingCount: pendingItems.length,
        goalTotal: boardsInPeriod.fold(Money.zero, (sum, b) => b.hasGoal ? sum + b.goal! : sum),
        plannedInBoards: allItems
            .where((i) => boardIdsInPeriod.contains(i.boardId))
            .fold(Money.zero, (sum, i) => sum + (i.estimatedValue ?? Money.zero)),
        boardsInPeriod: boardsInPeriod.length,
      );
    }

    final first = earliest;
    final last = latest;
    final daySpan = (start != null && end != null)
        ? end.difference(start).inDays + 1
        : (first != null && last != null ? last.difference(first).inDays + 1 : 0);
    final averagePerDay = daySpan <= 0 ? Money.zero : Money((total.cents / daySpan).round());

    ReportNamedTotal? topBox;
    if (boxTotals.isNotEmpty) {
      final topEntry = boxTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      topBox = ReportNamedTotal(id: topEntry.key, name: boxNameById[topEntry.key] ?? 'common.deletedBox'.tr, total: Money(topEntry.value));
    }

    ReportNamedTotal? topCategory;
    if (categoryTotals.isNotEmpty) {
      final topEntry = categoryTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final name = topEntry.key == 'sem_categoria' ? 'common.noCategory'.tr : (categoryNameById[topEntry.key] ?? 'common.deletedCategory'.tr);
      topCategory = ReportNamedTotal(id: topEntry.key, name: name, total: Money(topEntry.value));
    }

    ReportProductCount? mostPurchasedProduct;
    if (productQuantities.isNotEmpty) {
      final topEntry = productQuantities.entries.reduce((a, b) => a.value >= b.value ? a : b);
      mostPurchasedProduct = ReportProductCount(
        id: topEntry.key,
        name: productById[topEntry.key]?.name ?? 'reports.deletedProduct'.tr,
        quantity: topEntry.value,
      );
    }

    ReportNamedTotal? highestImpactProduct;
    if (productTotals.isNotEmpty) {
      final topEntry = productTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      highestImpactProduct = ReportNamedTotal(
        id: topEntry.key,
        name: productById[topEntry.key]?.name ?? 'reports.deletedProduct'.tr,
        total: Money(topEntry.value),
      );
    }

    final productLines = productTotals.entries.map((entry) {
      return ReportProductLine(
        id: entry.key,
        name: productById[entry.key]?.name ?? 'reports.deletedProduct'.tr,
        quantity: productQuantities[entry.key] ?? 0,
        total: Money(entry.value),
      );
    }).toList()
      ..sort((a, b) => b.total.cents.compareTo(a.total.cents));

    final evolution = <ReportEvolutionPoint>[];
    if (first != null && last != null) {
      var cursor = DateTime(first.year, first.month, 1);
      final lastMonth = DateTime(last.year, last.month, 1);
      while (!cursor.isAfter(lastMonth)) {
        evolution.add(ReportEvolutionPoint(month: cursor, total: Money(monthTotals[cursor] ?? 0)));
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
    }

    return Success(ConsolidatedReport(
      total: total,
      averagePerBox: averagePerBox,
      averagePerDay: averagePerDay,
      transactionCount: transactionCount,
      itemCount: itemCount,
      topBox: topBox,
      topCategory: topCategory,
      mostPurchasedProduct: mostPurchasedProduct,
      highestImpactProduct: highestImpactProduct,
      evolution: evolution,
      productLines: productLines,
      planning: planning,
    ));
  }
}
