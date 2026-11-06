import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/categories/domain/repositories/category_repository.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class MonthlyPoint {
  final DateTime month;
  final Money total;
  const MonthlyPoint({required this.month, required this.total});
}

class NamedSpend {
  final String id;
  final String name;
  final Money total;
  const NamedSpend({required this.id, required this.name, required this.total});
}

class DashboardCharts {
  final List<MonthlyPoint> monthlyEvolution;
  final List<NamedSpend> spendingByCategory;
  final List<NamedSpend> spendingByBox;
  final Money periodTotal;

  const DashboardCharts({
    required this.monthlyEvolution,
    required this.spendingByCategory,
    required this.spendingByBox,
    required this.periodTotal,
  });

  bool get isEmpty =>
      monthlyEvolution.every((p) => p.total.isZero) && spendingByCategory.isEmpty && spendingByBox.isEmpty;
}

/// Dados para os gráficos do Dashboard, com filtros opcionais de período,
/// Box e categoria. Diferente de [GetDashboardSummary] (que sempre olha o
/// mês atual para os cartões de resumo), este caso de uso responde a
/// filtros escolhidos pelo usuário.
class GetDashboardCharts {
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  const GetDashboardCharts({
    required this.boxRepository,
    required this.transactionRepository,
    required this.categoryRepository,
  });

  Future<Result<DashboardCharts>> call({
    required DateTime periodStart,
    required DateTime periodEnd,
    String? boxId,
    String? categoryId,
    int monthsForEvolution = 6,
  }) async {
    final boxesResult = await boxRepository.getAll();
    if (boxesResult.isFailure) return Failure(boxesResult.failureOrNull!);
    final categoriesResult = await categoryRepository.getAll(includeInactive: true);
    if (categoriesResult.isFailure) return Failure(categoriesResult.failureOrNull!);
    final transactionsResult = await transactionRepository.getAll(boxId: boxId);
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    final boxNameById = {for (final b in boxesResult.dataOrNull!) b.id: b.name};
    final categoryNameById = {for (final c in categoriesResult.dataOrNull!) c.id: c.name};
    final allTransactions = transactionsResult.dataOrNull!.where((t) => t.isClosed).toList();

    bool inPeriod(TransactionEntity t) =>
        !t.accountingDate.isBefore(periodStart) && !t.accountingDate.isAfter(periodEnd);

    Money itemsTotalForCategory(TransactionEntity t, String? forCategoryId) {
      final items = forCategoryId == null ? t.items : t.items.where((i) => i.categoryId == forCategoryId);
      return items.fold(Money.zero, (sum, i) => sum + i.total);
    }

    final periodTransactions = allTransactions.where(inPeriod).toList();
    final periodTotal = periodTransactions.fold(
      Money.zero,
      (sum, t) => sum + itemsTotalForCategory(t, categoryId),
    );

    // Evolução mensal: últimos [monthsForEvolution] meses até o mês de periodEnd.
    final evolutionEndMonth = DateTime(periodEnd.year, periodEnd.month, 1);
    final months = List.generate(monthsForEvolution, (i) {
      final target = DateTime(evolutionEndMonth.year, evolutionEndMonth.month - (monthsForEvolution - 1 - i), 1);
      return target;
    });
    final monthlyEvolution = months.map((month) {
      final total = allTransactions
          .where((t) => t.accountingDate.year == month.year && t.accountingDate.month == month.month)
          .fold(Money.zero, (sum, t) => sum + itemsTotalForCategory(t, categoryId));
      return MonthlyPoint(month: month, total: total);
    }).toList();

    // Gastos por categoria dentro do período (soma no nível do item).
    final categoryTotals = <String, int>{};
    for (final t in periodTransactions) {
      for (final item in t.items) {
        final key = item.categoryId ?? 'sem_categoria';
        categoryTotals[key] = (categoryTotals[key] ?? 0) + item.total.cents;
      }
    }
    final spendingByCategory = categoryTotals.entries.map((e) {
      final name = e.key == 'sem_categoria' ? 'Sem categoria' : (categoryNameById[e.key] ?? 'Categoria removida');
      return NamedSpend(id: e.key, name: name, total: Money(e.value));
    }).toList()
      ..sort((a, b) => b.total.cents.compareTo(a.total.cents));

    // Gastos por Box dentro do período (respeita o filtro de categoria).
    final boxTotals = <String, int>{};
    for (final t in periodTransactions) {
      boxTotals[t.boxId] = (boxTotals[t.boxId] ?? 0) + itemsTotalForCategory(t, categoryId).cents;
    }
    final spendingByBox = boxTotals.entries.map((e) {
      return NamedSpend(id: e.key, name: boxNameById[e.key] ?? 'Box removida', total: Money(e.value));
    }).toList()
      ..sort((a, b) => b.total.cents.compareTo(a.total.cents));

    return Success(DashboardCharts(
      monthlyEvolution: monthlyEvolution,
      spendingByCategory: spendingByCategory,
      spendingByBox: spendingByBox,
      periodTotal: periodTotal,
    ));
  }
}
