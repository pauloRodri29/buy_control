import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/features/categories/domain/entities/category_entity.dart';
import 'package:buy_control/features/categories/presentation/controllers/categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Formulário de criação/edição de categoria. Todo o estado fica local ao
/// widget (rascunho) — nada é persistido até o usuário tocar em Salvar.
class CategoryFormSheet extends StatefulWidget {
  final CategoryEntity? category;
  const CategoryFormSheet({super.key, this.category});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final controller = Get.find<CategoriesController>();
  late final nameController = TextEditingController(text: widget.category?.name);
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
    if (widget.category != null) {
      error = await controller.edit(widget.category!.copyWith(name: nameController.text));
    } else {
      error = await controller.create(name: nameController.text, icon: null);
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
        AppText.title(widget.category != null ? 'Editar categoria' : 'Nova categoria', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: nameController, label: 'Nome', hint: 'Bebidas'),
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
