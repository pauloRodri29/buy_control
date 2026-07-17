import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/presentation/controllers/units_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Formulário de criação/edição de unidade. Todo o estado fica local ao
/// widget (rascunho) — nada é persistido até o usuário tocar em Salvar.
class UnitFormSheet extends StatefulWidget {
  final UnitEntity? unit;
  const UnitFormSheet({super.key, this.unit});

  @override
  State<UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends State<UnitFormSheet> {
  final controller = Get.find<UnitsController>();
  late final nameController = TextEditingController(text: widget.unit?.name);
  late final abbreviationController = TextEditingController(text: widget.unit?.abbreviation);
  bool allowsDecimal = false;
  String? errorMessage;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    allowsDecimal = widget.unit?.allowsDecimal ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    abbreviationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => submitting = true);

    final String? error;
    if (widget.unit != null) {
      error = await controller.edit(widget.unit!.copyWith(
        name: nameController.text,
        abbreviation: abbreviationController.text,
        allowsDecimal: allowsDecimal,
      ));
    } else {
      error = await controller.create(
        name: nameController.text,
        abbreviation: abbreviationController.text,
        allowsDecimal: allowsDecimal,
      );
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
        AppText.title(widget.unit != null ? 'Editar unidade' : 'Nova unidade', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: nameController, label: 'Nome', hint: 'Quilo'),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: abbreviationController, label: 'Abreviação', hint: 'KG'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Checkbox(value: allowsDecimal, onChanged: (v) => setState(() => allowsDecimal = v ?? false)),
            const AppText('Permite quantidade fracionada (ex: 1,5 kg)'),
          ],
        ),
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
