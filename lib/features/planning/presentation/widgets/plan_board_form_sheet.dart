import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_date_picker.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

/// Formulário de criação/edição de quadro. Estado local (rascunho) até
/// tocar em Salvar. Com [template], cria um quadro novo copiando os itens
/// de outro (ex.: um quadro do Histórico).
class PlanBoardFormSheet extends StatefulWidget {
  final PlanBoardEntity? board;
  final PlanBoardEntity? template;
  const PlanBoardFormSheet({super.key, this.board, this.template});

  @override
  State<PlanBoardFormSheet> createState() => _PlanBoardFormSheetState();
}

class _PlanBoardFormSheetState extends State<PlanBoardFormSheet> {
  final controller = Get.find<PlanningController>();
  late final PlanBoardEntity? source = widget.board ?? widget.template;
  late final titleController = TextEditingController(text: source?.title);
  late final descriptionController = TextEditingController(text: source?.description);
  late final dateController = TextEditingController(text: DateTimeFormatter.ddMMyyyy(targetDate));
  late Money goal = source?.goal ?? Money.zero;
  late DateTime targetDate = widget.board?.targetDate ?? _endOfCurrentMonth();
  String? errorMessage;
  bool submitting = false;

  static DateTime _endOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await AppDatePicker.show(
      context,
      title: 'planning.plannedDate'.tr,
      initialDate: targetDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10, 12, 31),
      shortcuts: AppDatePicker.futureShortcuts(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      targetDate = picked;
      dateController.text = DateTimeFormatter.ddMMyyyy(picked);
    });
  }

  Future<void> _submit() async {
    setState(() => submitting = true);

    final description = descriptionController.text;
    final String? error;
    if (widget.board != null) {
      error = await controller.editBoard(widget.board!.copyWith(
        title: titleController.text.trim(),
        description: description.trim(),
        clearDescription: !Validators.isNotBlank(description),
        goal: goal,
        clearGoal: goal.isZero,
        targetDate: targetDate,
      ));
    } else if (widget.template != null) {
      error = await controller.addBoardFromTemplate(
        widget.template!,
        title: titleController.text,
        description: description,
        goal: goal,
        targetDate: targetDate,
      );
    } else {
      error = await controller.addBoard(
        title: titleController.text,
        description: description,
        goal: goal,
        targetDate: targetDate,
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading(widget.board != null ? 'planning.editBoard'.tr : 'planning.newBoard'.tr),
          if (widget.template != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText.subtitle('planning.itemsFromWillCopiedAllTitle'.trParams({'title': widget.template!.title})),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: titleController,
            label: 'common.title'.tr,
            hint: 'planning.yearEnd'.tr,
            autofocus: widget.board == null,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: descriptionController,
            label: 'common.descriptionOptional'.tr,
            hint: 'planning.giftsDinnerTravel'.tr,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: dateController,
            label: 'planning.plannedDate'.tr,
            readOnly: true,
            onTap: _pickDate,
            suffix: const Icon(Symbols.calendar_today, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          AppMoneyField(
            label: 'planning.spendingGoalOptional'.tr,
            initialValue: source?.goal,
            onChanged: (value) => goal = value,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(errorMessage!, color: context.colors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'common.save'.tr, onPressed: submitting ? null : _submit),
        ],
      ),
    );
  }
}
