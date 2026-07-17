import 'package:buy_control/app/navigation/main_shell.dart';
import 'package:get/get.dart';
part 'routes.dart';

class Pages {
  static final List<GetPage> pages = [
    GetPage(name: Routes.INITIAL, page: () => const MainShell()),
  ];
}
