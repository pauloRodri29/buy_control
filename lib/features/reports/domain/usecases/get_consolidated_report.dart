import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
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

class ConsolidatedReport {
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
  });

  bool get isEmpty => transactionCount == 0;
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

  const GetConsolidatedReport({
    required this.boxRepository,
    required this.transactionRepository,
    required this.categoryRepository,
    required this.productRepository,
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

    final boxFiltered = transactionsResult.dataOrNull!.where((t) {
      if (boxIds.isNotEmpty && !boxIds.contains(t.boxId)) return false;
      if (start != null && t.occurredAt.isBefore(start)) return false;
      if (end != null && t.occurredAt.isAfter(end)) return false;
      if (minValue != null && t.total.cents < minValue.cents) return false;
      if (maxValue != null && t.total.cents > maxValue.cents) return false;
      return true;
    }).toList();

    bool itemMatches(TransactionItemEntity item) {
      if (categoryIds.isNotEmpty && !categoryIds.contains(item.categoryId)) return false;
      if (productIds.isNotEmpty && !productIds.contains(item.productId)) return false;
      if (productTypeIds.isNotEmpty) {
        final product = item.productId == null ? null : productById[item.productId];
        if (product == null || !productTypeIds.contains(product.productTypeId)) return false;
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
    DateTime? earliest;
    DateTime? latest;

    for (final t in boxFiltered) {
      final matchingItems = hasItemFilters ? t.items.where(itemMatches).toList() : t.items;
      if (hasItemFilters && matchingItems.isEmpty) continue;

      transactionCount++;
      final transactionMatchedTotal = matchingItems.fold(Money.zero, (sum, i) => sum + i.total);
      total += transactionMatchedTotal;
      itemCount += matchingItems.length;
      boxTotals[t.boxId] = (boxTotals[t.boxId] ?? 0) + transactionMatchedTotal.cents;

      if (earliest == null || t.occurredAt.isBefore(earliest)) earliest = t.occurredAt;
      if (latest == null || t.occurredAt.isAfter(latest)) latest = t.occurredAt;

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

    final daySpan = (start != null && end != null)
        ? end.difference(start).inDays + 1
        : (earliest != null && latest != null ? latest.difference(earliest).inDays + 1 : 0);
    final averagePerDay = daySpan <= 0 ? Money.zero : Money((total.cents / daySpan).round());

    ReportNamedTotal? topBox;
    if (boxTotals.isNotEmpty) {
      final topEntry = boxTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      topBox = ReportNamedTotal(id: topEntry.key, name: boxNameById[topEntry.key] ?? 'Box removida', total: Money(topEntry.value));
    }

    ReportNamedTotal? topCategory;
    if (categoryTotals.isNotEmpty) {
      final topEntry = categoryTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final name = topEntry.key == 'sem_categoria' ? 'Sem categoria' : (categoryNameById[topEntry.key] ?? 'Categoria removida');
      topCategory = ReportNamedTotal(id: topEntry.key, name: name, total: Money(topEntry.value));
    }

    ReportProductCount? mostPurchasedProduct;
    if (productQuantities.isNotEmpty) {
      final topEntry = productQuantities.entries.reduce((a, b) => a.value >= b.value ? a : b);
      mostPurchasedProduct = ReportProductCount(
        id: topEntry.key,
        name: productById[topEntry.key]?.name ?? 'Produto removido',
        quantity: topEntry.value,
      );
    }

    ReportNamedTotal? highestImpactProduct;
    if (productTotals.isNotEmpty) {
      final topEntry = productTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      highestImpactProduct = ReportNamedTotal(
        id: topEntry.key,
        name: productById[topEntry.key]?.name ?? 'Produto removido',
        total: Money(topEntry.value),
      );
    }

    final evolution = <ReportEvolutionPoint>[];
    if (earliest != null && latest != null) {
      var cursor = DateTime(earliest.year, earliest.month, 1);
      final lastMonth = DateTime(latest.year, latest.month, 1);
      while (!cursor.isAfter(lastMonth)) {
        final monthCents = boxFiltered
            .where((t) => t.occurredAt.year == cursor.year && t.occurredAt.month == cursor.month)
            .expand((t) => hasItemFilters ? t.items.where(itemMatches) : t.items)
            .fold(0, (sum, i) => sum + i.total.cents);
        evolution.add(ReportEvolutionPoint(month: cursor, total: Money(monthCents)));
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
    ));
  }
}
