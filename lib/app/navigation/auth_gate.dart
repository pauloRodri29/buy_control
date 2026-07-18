import 'package:buy_control/app/navigation/main_shell.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Decide entre tela de login e o shell principal do app com base no
/// estado de sessão do [AuthController], que já é verificado em
/// `onInit()` assim que o app sobe (controller permanente).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        switch (controller.status) {
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case ViewStatus.empty:
          case ViewStatus.error:
            return const LoginPage();
          case ViewStatus.success:
            return const MainShell();
        }
      },
    );
  }
}
