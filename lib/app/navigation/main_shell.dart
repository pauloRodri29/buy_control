import 'package:buy_control/features/boxes/presentation/bindings/boxes_binding.dart';
import 'package:buy_control/features/boxes/presentation/controllers/boxes_controller.dart';
import 'package:buy_control/features/boxes/presentation/pages/boxes_page.dart';
import 'package:buy_control/features/dashboard/presentation/bindings/dashboard_binding.dart';
import 'package:buy_control/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:buy_control/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:buy_control/features/more/presentation/pages/more_page.dart';
import 'package:buy_control/features/planning/presentation/bindings/planning_binding.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:buy_control/features/planning/presentation/pages/planning_page.dart';
import 'package:buy_control/features/products/presentation/bindings/products_binding.dart';
import 'package:buy_control/features/products/presentation/controllers/products_controller.dart';
import 'package:buy_control/features/products/presentation/pages/products_page.dart';
import 'package:buy_control/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

/// Shell com Bottom Navigation. Todas as abas são registradas e montadas de
/// uma vez (`IndexedStack`) para preservar estado/scroll ao alternar, em
/// vez de recarregar a página a cada troca de aba.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _bound = false;

  void _bindTabsOnce() {
    if (_bound) return;
    // Plano do usuário que acabou de entrar: as abas recalculam os
    // bloqueios quando ele termina de carregar (addPlanListener).
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.find<SubscriptionController>().load());
    DashboardBinding().dependencies();
    BoxesBinding().dependencies();
    ProductsBinding().dependencies();
    PlanningBinding().dependencies();
    _bound = true;
  }

  @override
  Widget build(BuildContext context) {
    _bindTabsOnce();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardPage(),
          BoxesPage(),
          ProductsPage(),
          PlanningPage(),
          MorePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          // Os controllers das abas ficam vivos (IndexedStack preserva
          // estado), então recarregamos os dados ao entrar na aba para
          // refletir mudanças feitas em outra tela (ex.: novo lançamento).
          switch (i) {
            case 0:
              Get.find<DashboardController>().load();
            case 1:
              Get.find<BoxesController>().load();
            case 2:
              Get.find<ProductsController>().load();
            case 3:
              Get.find<PlanningController>().load(silent: true);
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Symbols.home), label: 'common.home'.tr),
          BottomNavigationBarItem(icon: Icon(Symbols.inventory_2), label: 'common.boxes'.tr),
          BottomNavigationBarItem(icon: Icon(Symbols.shopping_basket), label: 'common.products'.tr),
          BottomNavigationBarItem(icon: Icon(Symbols.view_kanban), label: 'common.plan'.tr),
          BottomNavigationBarItem(icon: Icon(Symbols.menu), label: 'common.more'.tr),
        ],
      ),
    );
  }
}
