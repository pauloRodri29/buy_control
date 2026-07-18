import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/auth/domain/entities/user_entity.dart';
import 'package:buy_control/features/auth/domain/usecases/get_current_user.dart';
import 'package:buy_control/features/auth/domain/usecases/login.dart';
import 'package:buy_control/features/auth/domain/usecases/logout.dart';
import 'package:buy_control/features/auth/domain/usecases/update_profile.dart';
import 'package:get/get.dart';

/// Controller de autenticação, registrado como singleton permanente (ver
/// `InitialBinding`) para que qualquer tela consiga `Get.find<AuthController>()`
/// a qualquer momento, sem depender de binding por rota.
///
/// Os campos que guardam os casos de uso `Login`, `Logout` e `UpdateProfile`
/// são privados com nomes diferentes dos métodos públicos de mesmo nome
/// (`login`, `logout`, `updateProfile`) porque `GetxController` não permite
/// um campo e um método com o mesmo identificador.
class AuthController extends GetxController {
  final Login _login;
  final Logout _logout;
  final GetCurrentUser getCurrentUser;
  final UpdateProfile _updateProfile;

  AuthController({
    required Login login,
    required Logout logout,
    required this.getCurrentUser,
    required UpdateProfile updateProfile,
  })  : _login = login,
        _logout = logout,
        _updateProfile = updateProfile;

  ViewStatus status = ViewStatus.initial;
  UserEntity? currentUser;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    checkSession();
  }

  Future<void> checkSession() async {
    status = ViewStatus.loading;
    update();

    final result = await getCurrentUser();
    result.fold((user) {
      currentUser = user;
      status = user != null ? ViewStatus.success : ViewStatus.empty;
    }, (failure) {
      status = ViewStatus.error;
      errorMessage = FailurePresenter.present(failure);
    });
    update();
  }

  Future<String?> login({required String email, required String password}) async {
    final result = await _login(email: email, password: password);
    return result.fold((user) {
      currentUser = user;
      errorMessage = null;
      status = ViewStatus.success;
      update();
      return null;
    }, (failure) {
      final message = FailurePresenter.present(failure);
      errorMessage = message;
      update();
      return message;
    });
  }

  Future<void> logout() async {
    await _logout();
    currentUser = null;
    status = ViewStatus.empty;
    update();
  }

  Future<String?> updateProfile({required String name, required String email}) async {
    final updated = currentUser!.copyWith(name: name, email: email);
    final result = await _updateProfile(updated);
    return result.fold((user) {
      currentUser = user;
      update();
      return null;
    }, (failure) => FailurePresenter.present(failure));
  }
}
