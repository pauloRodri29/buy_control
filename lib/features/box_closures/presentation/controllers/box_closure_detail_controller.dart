import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closure_details.dart';
import 'package:get/get.dart';

/// Detalhe somente leitura de um Fechamento. Fechamentos são definitivos:
/// não há ação de reabrir nem de editar.
class BoxClosureDetailController extends GetxController {
  final String closureId;
  final GetBoxClosureDetails getBoxClosureDetails;

  BoxClosureDetailController({required this.closureId, required this.getBoxClosureDetails});

  ViewStatus status = ViewStatus.initial;
  BoxClosureDetails? details;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final result = await getBoxClosureDetails(closureId);
    result.fold((data) {
      details = data;
      status = ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }
}
