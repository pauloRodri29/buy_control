import 'package:buy_control/app/navigation/auth_gate.dart';
import 'package:get/get.dart';
part 'routes.dart';

class Pages {
  static final List<GetPage> pages = [
    GetPage(name: Routes.INITIAL, page: () => const AuthGate()),
  ];
}
