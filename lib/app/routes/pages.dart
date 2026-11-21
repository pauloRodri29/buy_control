import 'package:buy_control/app/navigation/auth_gate.dart';
import 'package:buy_control/app/navigation/splash_page.dart';
import 'package:get/get.dart';
part 'routes.dart';

class Pages {
  static final List<GetPage> pages = [
    GetPage(name: Routes.SPLASH, page: () => const SplashPage()),
    GetPage(
      name: Routes.INITIAL,
      page: () => const AuthGate(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
    ),
  ];
}
