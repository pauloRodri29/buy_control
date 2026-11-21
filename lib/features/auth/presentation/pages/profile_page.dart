import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/auth/presentation/controllers/auth_controller.dart';
import 'package:buy_control/features/subscription/presentation/widgets/plan_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      title: 'common.signOutAccount'.tr,
      message: 'auth.youllNeedSignAgainEmail'.tr,
      confirmLabel: 'common.signOut'.tr,
    );
    if (confirmed) await controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final user = controller.currentUser;

    return Scaffold(
      appBar: AppBar(title: AppText.heading('common.profile'.tr, )),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Recarrega com o controller para refletir a edição do perfil.
                GetBuilder<AuthController>(
                  builder: (controller) {
                    final current = controller.currentUser ?? user;
                    return AppCard(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: context.colors.primary,
                              child: AppText.heading(_initials(current.name), color: context.colors.onPrimary),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(current.name, fontWeight: FontWeight.w600),
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText.subtitle(current.email),
                                ],
                              ),
                            ),
                            // Ações à direita: editar no topo, sair embaixo.
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'auth.editProfile'.tr,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Symbols.edit, size: 20, color: context.colors.primary),
                                  onPressed: () => _editProfile(context, controller),
                                ),
                                TextButton(
                                  onPressed: () => _logout(context, controller),
                                  style: TextButton.styleFrom(
                                    foregroundColor: context.colors.error,
                                    visualDensity: VisualDensity.compact,
                                    minimumSize: const Size(0, 32),
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                    textStyle: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  child: Text('common.signOut'.tr),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                const PlanSummaryCard(),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.subtitle('auth.memberSince'.tr),
                      AppText(DateTimeFormatter.ddMMyyyy(user.createdAt)),
                    ],
                  ),
                ),
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
        AppText.heading('auth.editProfile'.tr, ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: nameController, label: 'common.name'.tr),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: emailController, label: 'auth.email'.tr, keyboardType: TextInputType.emailAddress),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppText(errorMessage!, color: context.colors.error),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'common.save'.tr, onPressed: submitting ? null : _submit),
      ],
    );
  }
}
