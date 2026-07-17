import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/presentation/controllers/boxes_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Formulário de criação/edição de caixa. Todo o estado fica local ao
/// widget (rascunho) — nada é persistido até o usuário tocar em Salvar.
class BoxFormSheet extends StatefulWidget {
  final BoxEntity? box;
  const BoxFormSheet({super.key, this.box});

  @override
  State<BoxFormSheet> createState() => _BoxFormSheetState();
}

class _BoxFormSheetState extends State<BoxFormSheet> {
  final controller = Get.find<BoxesController>();
  late final nameController = TextEditingController(text: widget.box?.name);
  String? errorMessage;
  bool submitting = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => submitting = true);

    final String? error;
    if (widget.box != null) {
      error = await controller.edit(widget.box!.copyWith(name: nameController.text));
    } else {
      error = await controller.create(nameController.text);
    }

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
        AppText.title(widget.box != null ? 'Editar caixa' : 'Nova caixa', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: nameController, label: 'Nome', hint: 'Mercado do mês', autofocus: true),
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
