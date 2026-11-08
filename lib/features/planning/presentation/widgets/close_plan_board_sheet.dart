import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_date_picker.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Confirmação de fechamento de quadro: mostra o que será marcado como
/// comprado, o resultado final contra a meta e a data da compra (que
/// define o mês em que os valores entram nos relatórios).
class ClosePlanBoardSheet extends StatefulWidget {
  final PlanBoardEntity board;
  const ClosePlanBoardSheet({super.key, required this.board});

  @override
  State<ClosePlanBoardSheet> createState() => _ClosePlanBoardSheetState();
}

class _ClosePlanBoardSheetState extends State<ClosePlanBoardSheet> {
  final controller = Get.find<PlanningController>();
  late DateTime purchasedAt = _today();
  late final dateController = TextEditingController(text: DateTimeFormatter.ddMMyyyy(purchasedAt));
  String? errorMessage;
  bool submitting = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await AppDatePicker.show(
      context,
      title: 'Data da compra',
      initialDate: purchasedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      shortcuts: [
        ...AppDatePicker.recentShortcuts(),
        AppDateShortcut('Previsão do quadro', widget.board.targetDate),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      purchasedAt = picked;
      dateController.text = DateTimeFormatter.ddMMyyyy(picked);
    });
  }

  Future<void> _submit() async {
    setState(() => submitting = true);
    final error = await controller.close(widget.board, purchasedAt: purchasedAt);
    if (!mounted) return;
    setState(() {
      submitting = false;
      errorMessage = error;
    });
    if (error == null) {
      Navigator.of(context).pop();
      Get.snackbar('Quadro fechado', 'As compras de "${widget.board.title}" já entram nos relatórios.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = AppColors.textSecondary(isDark);

    final pending = controller.pendingItemsOf(widget.board.id);
    final pendingTotal = pending.fold(Money.zero, (sum, i) => sum + (i.estimatedValue ?? Money.zero));
    final withoutValue = pending.where((i) => i.estimatedValue == null || i.estimatedValue!.isZero).length;
    final progress = controller.progressOf(widget.board);

    final rows = <(String, String, Color?)>[
      ('Itens a marcar como comprados', '${pending.length}', null),
      ('Valor desses itens', pendingTotal.formatted, null),
      ('Total do quadro', progress.planned.formatted, null),
      if (progress.hasGoal) ('Meta', progress.goal!.formatted, null),
      if (progress.hasGoal)
        progress.isOverGoal
            ? ('Acima da meta', (progress.planned - progress.goal!).formatted, AppColors.error)
            : ('Abaixo da meta', progress.remaining!.formatted, AppColors.success),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title('Fechar "${widget.board.title}"?', fontSize: AppFontSizes.fz09, maxLines: 2),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            pending.isEmpty
                ? 'Todos os itens já estão comprados. O quadro será marcado como fechado.'
                : 'Os itens pendentes serão marcados como comprados na data abaixo e passam a contar '
                    'nos relatórios do mês dessa data.',
            color: secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant(isDark),
              borderRadius: AppRadius.borderMd,
            ),
            child: Column(
              children: [
                for (final (label, value, color) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(child: AppText(label, fontSize: AppFontSizes.fz06, color: secondary)),
                        AppText(value, fontSize: AppFontSizes.fz06, fontWeight: FontWeight.bold, color: color),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (withoutValue > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.triangleAlert, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppText.subtitle(
                    '$withoutValue ${withoutValue == 1 ? 'item está' : 'itens estão'} sem valor e '
                    'entrará${withoutValue == 1 ? '' : 'ão'} com R\$ 0,00. Edite antes se quiser registrar o valor.',
                    color: secondary,
                  ),
                ),
              ],
            ),
          ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: dateController,
              label: 'Data da compra',
              readOnly: true,
              onTap: _pickDate,
              suffix: const Icon(LucideIcons.calendar, size: 18),
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(errorMessage!, color: AppColors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(label: 'Fechar quadro', onPressed: submitting ? null : _submit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
