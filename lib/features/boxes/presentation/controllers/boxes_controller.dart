import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/usecases/archive_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/create_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/delete_box.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_summary.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_boxes.dart';
import 'package:buy_control/features/boxes/domain/usecases/update_box.dart';
import 'package:get/get.dart';

enum BoxSort { name, date, value }

class BoxesController extends GetxController {
  final GetBoxes getBoxes;
  final GetBoxSummary getBoxSummary;
  final CreateBox createBox;
  final UpdateBox updateBox;
  final DeleteBox deleteBox;
  final ArchiveBox archiveBox;

  BoxesController({
    required this.getBoxes,
    required this.getBoxSummary,
    required this.createBox,
    required this.updateBox,
    required this.deleteBox,
    required this.archiveBox,
  });

  ViewStatus status = ViewStatus.initial;
  List<BoxEntity> boxes = [];
  Map<String, BoxSummary> summaries = {};
  String? errorMessage;
  BoxSort sort = BoxSort.date;

  List<BoxEntity> _allBoxes = [];
  String _query = '';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final result = await getBoxes();
    final failure = result.failureOrNull;
    if (failure != null) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
      update();
      return;
    }

    _allBoxes = result.dataOrNull!;

    // Busca o resumo (total, contagem de lançamentos, última movimentação)
    // de todas as caixas de uma vez após carregar a lista, para os cards
    // não precisarem de uma consulta extra durante o build.
    final entries = await Future.wait(_allBoxes.map((box) async {
      final summaryResult = await getBoxSummary(box.id);
      return MapEntry(box.id, summaryResult.dataOrNull);
    }));
    summaries = {
      for (final entry in entries)
        if (entry.value != null) entry.key: entry.value!,
    };

    _applyFilters();
  }

  void search(String query) {
    _query = query;
    _applyFilters();
  }

  void setSort(BoxSort value) {
    sort = value;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _allBoxes;
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((b) => b.name.toLowerCase().contains(query)).toList();
    }

    final sorted = [...filtered];
    switch (sort) {
      case BoxSort.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case BoxSort.date:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case BoxSort.value:
        sorted.sort((a, b) {
          final totalA = summaries[a.id]?.total.cents ?? 0;
          final totalB = summaries[b.id]?.total.cents ?? 0;
          return totalB.compareTo(totalA);
        });
    }

    boxes = sorted;
    status = boxes.isEmpty ? ViewStatus.empty : ViewStatus.success;
    update();
  }

  Future<String?> create(String name) async {
    final result = await createBox(name: name);
    return result.fold((outcome) {
      if (outcome.hasDuplicateName) {
        Get.snackbar('Nome duplicado', 'Já existe uma caixa chamada "${outcome.box.name}".');
      }
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<String?> edit(BoxEntity box) async {
    final result = await updateBox(box);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<void> delete(String id) async {
    await deleteBox(id);
    await load();
  }

  Future<void> archive(String id, {bool archived = true}) async {
    await archiveBox(id, archived: archived);
    await load();
  }
}
