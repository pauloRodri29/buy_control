import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_date_picker.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_board_form_sheet.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_history_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

enum _HistoryMenu { useAsTemplate, delete }

/// Detalhe de um quadro do Histórico (somente leitura, exceto a data e o
/// valor pago de cada compra). Não há "reabrir": para repetir a lista,
/// "Usar como modelo" cria um quadro novo com os mesmos itens.
class PlanBoardHistoryPage extends StatelessWidget {
  final String boardId;
  const PlanBoardHistoryPage({super.key, required this.boardId});

  PlanningController get _controller => Get.find<PlanningController>();

  Future<void> _onMenu(BuildContext context, PlanBoardEntity board, _HistoryMenu option) async {
    switch (option) {
      case _HistoryMenu.useAsTemplate:
        await AppBottomSheet.show<void>(context, child: PlanBoardFormSheet(template: board));
      case _HistoryMenu.delete:
        final confirmed = await ConfirmDialog.show(
          context,
          title: 'Excluir "${board.title}" do histórico?',
          message: 'As compras deste quadro deixam de contar nos relatórios. Itens que estão em '
              'Pendências continuam lá. Esta ação não pode ser desfeita.',
        );
        if (!confirmed) return;
        final error = await _controller.removeBoard(board.id, deleteItems: false);
        if (error != null) {
          AppFeedback.error(error, title: 'Não foi possível excluir');
          return;
        }
        if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlanningController>(
      builder: (controller) {
        final board = controller.boardById(boardId);
        if (board == null) {
          return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
        }

        final items = controller.historyItemsOf(board.id);
        final purchased = items.where((i) => i.isPurchased).toList()
          ..sort((a, b) => (a.purchasedAt ?? a.updatedAt).compareTo(b.purchasedAt ?? b.updatedAt));
        final notPurchased = items.where((i) => !i.isPurchased).toList();
        final progress = controller.historyProgressOf(board);
        final secondary = context.colors.onSurfaceVariant;

        return Scaffold(
          appBar: AppBar(
            title: AppText.heading(board.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              PopupMenuButton<_HistoryMenu>(
                icon: const Icon(Symbols.more_vert),
                onSelected: (option) => _onMenu(context, board, option),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _HistoryMenu.useAsTemplate, child: Text('Usar como modelo')),
                  PopupMenuItem(value: _HistoryMenu.delete, child: Text('Excluir do histórico')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            children: [
              Row(children: [PlanBoardStatusChip(board: board)]),
              const SizedBox(height: AppSpacing.sm),
              AppText.subtitle(
                '${board.isCancelled ? 'Cancelado' : 'Finalizado'} em ${DateTimeFormatter.ddMMyyyy(board.finishedAt!)}'
                ' · previsão ${DateTimeFormatter.ddMMyyyy(board.targetDate)}',
                color: secondary,
              ),
              if (board.description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppText.subtitle(board.description!, color: secondary),
              ],
              const SizedBox(height: AppSpacing.md),
              _Summary(spent: progress.purchased, goal: progress.goal, purchased: purchased.length, total: items.length),
              const SizedBox(height: AppSpacing.lg),
              AppText('Comprados (${purchased.length})', fontWeight: FontWeight.bold),
              const SizedBox(height: AppSpacing.xs),
              AppText.subtitle('Toque em uma compra para ajustar a data ou o valor pago.', color: secondary),
              const SizedBox(height: AppSpacing.sm),
              if (purchased.isEmpty) AppText.subtitle('Nenhum item comprado.', color: secondary),
              for (final item in purchased)
                _PurchasedTile(
                  item: item,
                  onTap: () => AppBottomSheet.show<void>(context, child: _PurchaseEditSheet(item: item)),
                ),
              if (notPurchased.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppText('Não comprados (${notPurchased.length})', fontWeight: FontWeight.bold),
                const SizedBox(height: AppSpacing.sm),
                for (final item in notPurchased)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Symbols.remove_shopping_cart, color: secondary),
                    title: AppText(item.title),
                    subtitle: AppText.subtitle(
                      [if (item.notPurchasedReason != null) item.notPurchasedReason!, 'em Pendências'].join(' · '),
                      color: secondary,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  final Money spent;
  final Money? goal;
  final int purchased;
  final int total;

  const _Summary({required this.spent, required this.goal, required this.purchased, required this.total});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final goal = this.goal;
    final over = goal != null && spent > goal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: context.colors.surfaceContainerHighest, borderRadius: AppRadius.borderMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle('Total gasto', color: secondary),
          AppText.title(spent.formatted),
          const SizedBox(height: AppSpacing.xs),
          AppText.subtitle('$purchased de $total itens comprados', color: secondary),
          if (goal != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: LinearProgressIndicator(
                value: goal.isZero ? 1 : (spent.cents / goal.cents).clamp(0, 1).toDouble(),
                minHeight: 6,
                color: over ? context.colors.error : context.semantic.success,
                backgroundColor: context.colors.outlineVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText.subtitle(
              over
                  ? '${(spent - goal).formatted} acima da meta de ${goal.formatted}'
                  : '${(goal - spent).formatted} abaixo da meta de ${goal.formatted}',
              color: over ? context.colors.error : context.semantic.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _PurchasedTile extends StatelessWidget {
  final PlanItemEntity item;
  final VoidCallback onTap;
  const _PurchasedTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final value = item.value;
    final date = item.purchasedAt ?? item.updatedAt;
    final valueLabel = item.paidValue != null && !item.paidValue!.isZero ? 'pago' : 'estimado';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(Symbols.check_circle, fill: 1, color: context.semantic.success),
      title: AppText(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: AppText.subtitle('Comprado em ${DateTimeFormatter.ddMMyyyy(date)}', color: secondary),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppText.small(value?.formatted ?? 'Sem valor', fontWeight: FontWeight.bold, color: value == null ? secondary : null),
          if (value != null) AppText.subtitle(valueLabel, color: secondary),
        ],
      ),
    );
  }
}

/// Ajusta a data e o valor pago de uma compra já feita. A data define o
/// mês em que a compra entra nos relatórios.
class _PurchaseEditSheet extends StatefulWidget {
  final PlanItemEntity item;
  const _PurchaseEditSheet({required this.item});

  @override
  State<_PurchaseEditSheet> createState() => _PurchaseEditSheetState();
}

class _PurchaseEditSheetState extends State<_PurchaseEditSheet> {
  final controller = Get.find<PlanningController>();
  late DateTime purchasedAt = _dateOnly(widget.item.purchasedAt ?? widget.item.updatedAt);
  late final dateController = TextEditingController(text: DateTimeFormatter.ddMMyyyy(purchasedAt));
  late Money paid = widget.item.value ?? Money.zero;
  String? errorMessage;
  bool submitting = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
      shortcuts: AppDatePicker.recentShortcuts(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      purchasedAt = picked;
      dateController.text = DateTimeFormatter.ddMMyyyy(picked);
    });
  }

  Future<void> _submit() async {
    setState(() => submitting = true);
    final item = widget.item;
    // Mantém o horário original quando o dia não mudou.
    final original = item.purchasedAt;
    final date = original != null && _dateOnly(original) == purchasedAt ? original : purchasedAt;
    // Só registra como "pago" quando difere do estimado.
    final sameAsEstimate = item.estimatedValue != null && paid == item.estimatedValue;

    final error = await controller.editItem(item.copyWith(
      purchasedAt: date,
      paidValue: paid.isZero || sameAsEstimate ? null : paid,
      clearPaidValue: paid.isZero || sameAsEstimate,
    ));
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
          AppText.heading(widget.item.title, maxLines: 2),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: dateController,
            label: 'Data da compra',
            readOnly: true,
            onTap: _pickDate,
            suffix: const Icon(Symbols.calendar_today, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          AppMoneyField(
            label: 'Valor pago',
            initialValue: widget.item.value,
            onChanged: (v) => paid = v,
          ),
          if (widget.item.estimatedValue != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText.subtitle('Estimado: ${widget.item.estimatedValue!.formatted}'),
          ],
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
