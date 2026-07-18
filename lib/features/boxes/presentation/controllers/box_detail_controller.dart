import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/box_closures/domain/usecases/close_box.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_summary.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:buy_control/features/transactions/domain/usecases/get_transactions_by_box.dart';
import 'package:buy_control/features/transactions/domain/usecases/search_transactions.dart';
import 'package:buy_control/features/transactions/domain/usecases/transaction_sort.dart';
import 'package:get/get.dart';

class BoxDetailController extends GetxController {
  final BoxEntity box;
  final GetBoxSummary getBoxSummary;
  final GetTransactionsByBox getTransactionsByBox;
  final SearchTransactions searchTransactions;
  final DeleteTransaction deleteTransaction;
  final CloseBox closeBoxUseCase;

  BoxDetailController({
    required this.box,
    required this.getBoxSummary,
    required this.getTransactionsByBox,
    required this.searchTransactions,
    required this.deleteTransaction,
    required this.closeBoxUseCase,
  });

  ViewStatus status = ViewStatus.initial;
  BoxSummary? summary;
  List<TransactionEntity> transactions = [];
  TransactionSort sort = TransactionSort.newest;
  String? errorMessage;

  String _query = '';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final summaryResult = await getBoxSummary(box.id);
    summary = summaryResult.dataOrNull;

    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final query = _query.trim();
    final result = query.isEmpty
        ? await getTransactionsByBox(box.id, sort: sort)
        : await searchTransactions(boxId: box.id, query: query);

    result.fold((data) {
      final open = data.where((t) => !t.isClosed).toList();
      transactions = query.isEmpty ? open : _sorted(open);
      status = transactions.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }

  // SearchTransactions não ordena o resultado: aplica-se localmente a
  // mesma ordenação escolhida pelo usuário para a busca ficar consistente
  // com a listagem normal.
  List<TransactionEntity> _sorted(List<TransactionEntity> data) {
    final sorted = [...data];
    switch (sort) {
      case TransactionSort.newest:
        sorted.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      case TransactionSort.oldest:
        sorted.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      case TransactionSort.highestValue:
        sorted.sort((a, b) => b.total.cents.compareTo(a.total.cents));
      case TransactionSort.lowestValue:
        sorted.sort((a, b) => a.total.cents.compareTo(b.total.cents));
      case TransactionSort.name:
        sorted.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
      case TransactionSort.highestQuantity:
        sorted.sort((a, b) => _quantity(b).compareTo(_quantity(a)));
    }
    return sorted;
  }

  double _quantity(TransactionEntity transaction) {
    return transaction.items.fold(0.0, (sum, item) => sum + item.quantity);
  }

  void search(String query) {
    _query = query;
    _loadTransactions();
  }

  void setSort(TransactionSort value) {
    sort = value;
    _loadTransactions();
  }

  Future<void> removeTransaction(String id) async {
    await deleteTransaction(id);
    await load();
  }

  Future<String?> closeBox({String? notes}) async {
    final result = await closeBoxUseCase(boxId: box.id, notes: notes);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }
}
