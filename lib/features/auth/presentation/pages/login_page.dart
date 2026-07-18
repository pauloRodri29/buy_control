import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_icon.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controller = Get.find<AuthController>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? errorMessage;
  bool submitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      submitting = true;
      errorMessage = null;
    });

    final error = await controller.login(
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      submitting = false;
      errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppIcon(LucideIcons.box, size: 48, color: AppColors.accent),
                const SizedBox(height: AppSpacing.md),
                const AppText.title('Buy Control', textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                AppText.subtitle(
                  'Entre para continuar',
                  color: AppColors.textSecondary(isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  controller: emailController,
                  label: 'E-mail',
                  hint: 'voce@exemplo.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: passwordController,
                  label: 'Senha',
                  hint: 'Mínimo 4 caracteres',
                  obscureText: true,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppText(errorMessage!, color: AppColors.error),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Entrar', onPressed: submitting ? null : _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
