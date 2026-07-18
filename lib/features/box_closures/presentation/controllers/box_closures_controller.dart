import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closures.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:get/get.dart';

class BoxClosuresController extends GetxController {
  final BoxEntity box;
  final GetBoxClosures getBoxClosures;

  BoxClosuresController({required this.box, required this.getBoxClosures});

  ViewStatus status = ViewStatus.initial;
  List<BoxClosureEntity> closures = [];
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final result = await getBoxClosures(box.id);
    result.fold((data) {
      closures = data;
      status = closures.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }
}
