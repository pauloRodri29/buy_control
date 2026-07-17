import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/features/product_types/domain/entities/product_type_entity.dart';
import 'package:buy_control/features/product_types/presentation/controllers/product_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Formulário de criação/edição de tipo de produto. Todo o estado fica
/// local ao widget (rascunho) — nada é persistido até o usuário tocar em
/// Salvar.
class ProductTypeFormSheet extends StatefulWidget {
  final ProductTypeEntity? productType;
  const ProductTypeFormSheet({super.key, this.productType});

  @override
  State<ProductTypeFormSheet> createState() => _ProductTypeFormSheetState();
}

class _ProductTypeFormSheetState extends State<ProductTypeFormSheet> {
  final controller = Get.find<ProductTypesController>();
  late final nameController = TextEditingController(text: widget.productType?.name);
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
    if (widget.productType != null) {
      error = await controller.edit(widget.productType!.copyWith(name: nameController.text));
    } else {
      error = await controller.create(name: nameController.text);
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
        AppText.title(widget.productType != null ? 'Editar tipo' : 'Novo tipo', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: nameController, label: 'Nome', hint: 'Alimentício'),
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
