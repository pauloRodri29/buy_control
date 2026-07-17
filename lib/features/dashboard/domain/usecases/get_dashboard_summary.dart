import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/repositories/transaction_repository.dart';

class BoxSpend {
  final String boxId;
  final String boxName;
  final Money total;
  const BoxSpend({required this.boxId, required this.boxName, required this.total});
}

class DashboardSummary {
  final Money currentMonthTotal;
  final Money previousMonthTotal;
  final double? percentChangeVsPreviousMonth;
  final Money dailyAverageCurrentMonth;
  final int transactionCountCurrentMonth;
  final int activeBoxCount;
  final List<BoxSpend> topBoxesCurrentMonth;
  final List<TransactionEntity> recentTransactions;

  const DashboardSummary({
    required this.currentMonthTotal,
    required this.previousMonthTotal,
    required this.percentChangeVsPreviousMonth,
    required this.dailyAverageCurrentMonth,
    required this.transactionCountCurrentMonth,
    required this.activeBoxCount,
    required this.topBoxesCurrentMonth,
    required this.recentTransactions,
  });
}

class GetDashboardSummary {
  final BoxRepository boxRepository;
  final TransactionRepository transactionRepository;

  const GetDashboardSummary({required this.boxRepository, required this.transactionRepository});

  Future<Result<DashboardSummary>> call({DateTime? referenceDate}) async {
    final boxesResult = await boxRepository.getAll();
    if (boxesResult.isFailure) return Failure(boxesResult.failureOrNull!);

    final transactionsResult = await transactionRepository.getAll();
    if (transactionsResult.isFailure) return Failure(transactionsResult.failureOrNull!);

    final boxes = boxesResult.dataOrNull!;
    final boxNameById = {for (final b in boxes) b.id: b.name};
    final transactions = transactionsResult.dataOrNull!;

    final now = referenceDate ?? DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);

    bool isInMonth(DateTime date, DateTime monthStart) {
      return date.year == monthStart.year && date.month == monthStart.month;
    }

    final currentMonthTransactions = transactions.where((t) => isInMonth(t.occurredAt, currentMonthStart)).toList();
    final previousMonthTransactions = transactions.where((t) => isInMonth(t.occurredAt, previousMonthStart)).toList();

    final currentMonthTotal = currentMonthTransactions.fold(Money.zero, (sum, t) => sum + t.total);
    final previousMonthTotal = previousMonthTransactions.fold(Money.zero, (sum, t) => sum + t.total);

    final percentChange = previousMonthTotal.cents == 0
        ? null
        : ((currentMonthTotal.cents - previousMonthTotal.cents) / previousMonthTotal.cents) * 100;

    final daysElapsedInMonth = now.month == currentMonthStart.month && now.year == currentMonthStart.year
        ? now.day
        : DateTime(currentMonthStart.year, currentMonthStart.month + 1, 0).day;
    final dailyAverage = daysElapsedInMonth == 0
        ? Money.zero
        : Money((currentMonthTotal.cents / daysElapsedInMonth).round());

    final spendByBox = <String, int>{};
    for (final t in currentMonthTransactions) {
      spendByBox[t.boxId] = (spendByBox[t.boxId] ?? 0) + t.total.cents;
    }
    final topBoxes = spendByBox.entries.map((e) {
      return BoxSpend(boxId: e.key, boxName: boxNameById[e.key] ?? 'Box removida', total: Money(e.value));
    }).toList()
      ..sort((a, b) => b.total.cents.compareTo(a.total.cents));

    final recent = [...transactions]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return Success(DashboardSummary(
      currentMonthTotal: currentMonthTotal,
      previousMonthTotal: previousMonthTotal,
      percentChangeVsPreviousMonth: percentChange,
      dailyAverageCurrentMonth: dailyAverage,
      transactionCountCurrentMonth: currentMonthTransactions.length,
      activeBoxCount: boxes.length,
      topBoxesCurrentMonth: topBoxes.take(3).toList(),
      recentTransactions: recent.take(5).toList(),
    ));
  }
}
