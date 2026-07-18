import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _editProfile(BuildContext context, AuthController controller) {
    return AppBottomSheet.show(context, child: _ProfileEditForm(controller: controller));
  }

  Future<void> _logout(BuildContext context, AuthController controller) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente com seu e-mail e senha para acessar o app.',
      confirmLabel: 'Sair',
    );
    if (confirmed) await controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = controller.currentUser;

    return Scaffold(
      appBar: AppBar(title: const AppText.title('Perfil', fontSize: AppFontSizes.fz09)),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accent,
                        child: AppText(
                          _initials(user.name),
                          fontSize: AppFontSizes.fz09,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnDarkButton,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(user.name, fontWeight: FontWeight.w600),
                            const SizedBox(height: AppSpacing.xs),
                            AppText.subtitle(user.email, color: AppColors.textSecondary(isDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.subtitle('Membro desde', color: AppColors.textSecondary(isDark)),
                      AppText(DateTimeFormatter.ddMMyyyy(user.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.secondary(label: 'Editar perfil', onPressed: () => _editProfile(context, controller)),
                const SizedBox(height: AppSpacing.md),
                AppButton.danger(label: 'Sair', onPressed: () => _logout(context, controller)),
              ],
            ),
    );
  }
}

class _ProfileEditForm extends StatefulWidget {
  final AuthController controller;
  const _ProfileEditForm({required this.controller});

  @override
  State<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<_ProfileEditForm> {
  late final nameController = TextEditingController(text: widget.controller.currentUser?.name);
  late final emailController = TextEditingController(text: widget.controller.currentUser?.email);
  String? errorMessage;
  bool submitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => submitting = true);

    final error = await widget.controller.updateProfile(
      name: nameController.text,
      email: emailController.text,
    );

    if (!mounted) return;
    setState(() {
      submitting = false;
      errorMessage = error;
    });

    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.title('Editar perfil', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: nameController, label: 'Nome'),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: emailController, label: 'E-mail', keyboardType: TextInputType.emailAddress),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppText(errorMessage!, color: AppColors.error),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Salvar', onPressed: submitting ? null : _submit),
      ],
    );
  }
}
