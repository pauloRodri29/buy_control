import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/domain/usecases/create_unit.dart';
import 'package:buy_control/features/units/domain/usecases/delete_unit.dart';
import 'package:buy_control/features/units/domain/usecases/get_units.dart';
import 'package:buy_control/features/units/domain/usecases/update_unit.dart';
import 'package:get/get.dart';

class UnitsController extends GetxController {
  final GetUnits getUnits;
  final CreateUnit createUnit;
  final UpdateUnit updateUnit;
  final DeleteUnit deleteUnit;

  UnitsController({
    required this.getUnits,
    required this.createUnit,
    required this.updateUnit,
    required this.deleteUnit,
  });

  ViewStatus status = ViewStatus.initial;
  List<UnitEntity> units = [];
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final result = await getUnits();
    result.fold((data) {
      units = data;
      status = data.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }

  Future<String?> create({required String name, required String abbreviation, bool allowsDecimal = false}) async {
    final result = await createUnit(name: name, abbreviation: abbreviation, allowsDecimal: allowsDecimal);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<String?> edit(UnitEntity unit) async {
    final result = await updateUnit(unit);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<void> delete(String id) async {
    await deleteUnit(id);
    await load();
  }
}
