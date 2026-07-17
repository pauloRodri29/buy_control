import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/domain/usecases/create_category.dart';
import 'package:buy_control/features/categories/domain/usecases/delete_category.dart';
import 'package:buy_control/features/categories/domain/usecases/get_categories.dart';
import 'package:buy_control/features/categories/domain/usecases/update_category.dart';
import 'package:get/get.dart';

class CategoriesController extends GetxController {
  final GetCategories getCategories;
  final CreateCategory createCategory;
  final UpdateCategory updateCategory;
  final DeleteCategory deleteCategory;

  CategoriesController({
    required this.getCategories,
    required this.createCategory,
    required this.updateCategory,
    required this.deleteCategory,
  });

  ViewStatus status = ViewStatus.initial;
  List<CategoryEntity> categories = [];
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    update();

    final result = await getCategories();
    result.fold((data) {
      categories = data;
      status = data.isEmpty ? ViewStatus.empty : ViewStatus.success;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }

  Future<String?> create({required String name, String? icon}) async {
    final result = await createCategory(name: name, icon: icon);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<String?> edit(CategoryEntity category) async {
    final result = await updateCategory(category);
    return result.fold((_) {
      load();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }

  Future<void> delete(String id) async {
    await deleteCategory(id);
    await load();
  }
}
