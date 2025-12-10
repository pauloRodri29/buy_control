import 'package:buy_control/app/screens/home_screen/home_screen.dart';
import 'package:get/get.dart';
part 'routes.dart';

class Pages {
  static final List<GetPage> pages = [
    GetPage(name: Routes.INITIAL, page: () => HomeScreen()),
    // GetPage(name: Routes.HOME, page: () => const HomePage()),
    // GetPage(name: Routes.BOX, page: () => const BoxScreen()),
  ];
}
