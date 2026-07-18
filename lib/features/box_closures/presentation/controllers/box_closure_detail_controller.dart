import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closure_details.dart';
import 'package:buy_control/features/box_closures/domain/usecases/reopen_box_closure.dart';
import 'package:get/get.dart';

class BoxClosureDetailController extends GetxController {
  final String closureId;
  final GetBoxClosureDetails getBoxClosureDetails;
  final ReopenBoxClosure reopenBoxClosure;

  BoxClosureDetailController({
    required this.closureId,
    required this.getBoxClosureDetails,
    required this.reopenBoxClosure,
  });

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

  Future<String?> reopen() async {
    final result = await reopenBoxClosure(closureId);
    return result.fold((_) => null, (failure) => FailurePresenter.present(failure));
  }
}
