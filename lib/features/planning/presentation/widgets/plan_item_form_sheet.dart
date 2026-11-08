import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/validators/validators.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Formulário de criação/edição de item planejado.
class PlanItemFormSheet extends StatefulWidget {
  final PlanItemEntity? item;

  /// Quadro pré-selecionado ao criar a partir de uma coluna.
  final String? initialBoardId;

  const PlanItemFormSheet({super.key, this.item, this.initialBoardId});

  @override
  State<PlanItemFormSheet> createState() => _PlanItemFormSheetState();
}

class _PlanItemFormSheetState extends State<PlanItemFormSheet> {
  /// O dropdown não distingue bem `null` de "sem seleção", então "Sem
  /// quadro" usa um valor sentinela.
  static const _noBoard = '';

  final controller = Get.find<PlanningController>();
  late final titleController = TextEditingController(text: widget.item?.title);
  late final descriptionController = TextEditingController(text: widget.item?.description);
  late Money value = widget.item?.estimatedValue ?? Money.zero;
  late String boardId = (widget.item != null ? widget.item!.boardId : widget.initialBoardId) ?? _noBoard;
  String? errorMessage;
  bool submitting = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => submitting = true);

    final description = descriptionController.text;
    final selectedBoard = boardId == _noBoard ? null : boardId;
    final String? error;
    if (widget.item != null) {
      error = await controller.editItem(widget.item!.copyWith(
        title: titleController.text.trim(),
        description: description.trim(),
        clearDescription: !Validators.isNotBlank(description),
        estimatedValue: value,
        clearEstimatedValue: value.isZero,
        boardId: selectedBoard,
        clearBoard: selectedBoard == null,
      ));
    } else {
      error = await controller.addItem(
        boardId: selectedBoard,
        title: titleController.text,
        description: description,
        estimatedValue: value,
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
    // Um item já num quadro arquivado continua com esse quadro na lista.
    final boards = [
      ...controller.activeBoards,
      ...controller.boards.where((b) => b.isArchived && b.id == widget.item?.boardId),
    ];
    if (boardId != _noBoard && !boards.any((b) => b.id == boardId)) boardId = _noBoard;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading(widget.item != null ? 'Editar item' : 'Novo item', ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: titleController,
            label: 'Título',
            hint: 'Air fryer',
            autofocus: widget.item == null,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: descriptionController,
            label: 'Descrição (opcional)',
            hint: 'Modelo, loja, link...',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          AppMoneyField(
            label: 'Valor estimado (opcional)',
            initialValue: widget.item?.estimatedValue,
            onChanged: (v) => value = v,
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Quadro',
            value: boardId,
            options: [
              const AppDropdownOption(value: _noBoard, label: 'Sem quadro'),
              for (final b in boards)
                AppDropdownOption(value: b.id, label: '${b.title} · ${DateTimeFormatter.ddMMyyyy(b.targetDate)}'),
            ],
            onChanged: (v) => setState(() => boardId = v ?? _noBoard),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(errorMessage!, color: context.colors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Salvar', onPressed: submitting ? null : _submit),
        ],
      ),
    );
  }
}
