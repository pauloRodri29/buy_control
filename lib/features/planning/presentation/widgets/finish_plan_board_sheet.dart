import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/domain/usecases/plan_board_usecases.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Motivos prontos para um item não comprado (o último abre texto livre).
const notPurchasedReasons = ['Sem estoque', 'Preço alto', 'Não precisei', 'Deixei para depois', 'Outro'];
const _otherReason = 'Outro';

/// Valor do seletor de destino que manda o item para Pendências.
const _toPending = '__pending__';

/// Finalização (ou cancelamento) de um quadro. É definitivo, então a tela
/// resolve tudo antes:
/// - cada item não comprado vai para outro quadro aberto ou para
///   Pendências, com um motivo (sem outros quadros, só Pendências);
/// - itens comprados sem valor podem receber o valor pago.
class FinishPlanBoardSheet extends StatefulWidget {
  final PlanBoardEntity board;
  final PlanBoardEnding ending;

  const FinishPlanBoardSheet({super.key, required this.board, this.ending = PlanBoardEnding.finish});

  @override
  State<FinishPlanBoardSheet> createState() => _FinishPlanBoardSheetState();
}

class _FinishPlanBoardSheetState extends State<FinishPlanBoardSheet> {
  final controller = Get.find<PlanningController>();

  late final List<PlanItemEntity> unpurchased = controller.unpurchasedItemsOf(widget.board.id);
  late final List<PlanItemEntity> withoutValue = controller.purchasedWithoutValueOf(widget.board.id);
  late final List<PlanBoardEntity> otherBoards = controller.destinationsFor(widget.board);

  /// itemId → id do quadro de destino ou [_toPending].
  late final Map<String, String?> destination = {
    for (final i in unpurchased) i.id: otherBoards.isEmpty ? _toPending : null,
  };
  final Map<String, String> reason = {};
  final Map<String, TextEditingController> otherReason = {};
  final Map<String, Money> paid = {};
  bool registerValues = false;

  String? errorMessage;
  bool submitting = false;

  bool get isCancel => widget.ending == PlanBoardEnding.cancel;

  @override
  void dispose() {
    for (final c in otherReason.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _otherReasonOf(String itemId) => otherReason.putIfAbsent(itemId, TextEditingController.new);

  String? _reasonFor(String itemId) {
    final selected = reason[itemId];
    if (selected == _otherReason) {
      final text = otherReason[itemId]?.text.trim() ?? '';
      return text.isEmpty ? null : text;
    }
    return selected;
  }

  /// Monta os destinos; devolve a mensagem do primeiro problema, se houver.
  (Map<String, PendingItemDestination>, String?) _collectDestinations() {
    final result = <String, PendingItemDestination>{};
    for (final item in unpurchased) {
      final target = destination[item.id];
      if (target == null) return (result, 'Escolha para onde vai "${item.title}".');
      if (target == _toPending) {
        final why = _reasonFor(item.id);
        if (why == null) return (result, 'Informe o motivo de não ter comprado "${item.title}".');
        result[item.id] = PendingItemDestination.pending(why);
      } else {
        result[item.id] = PendingItemDestination.board(target);
      }
    }
    return (result, null);
  }

  Future<void> _submit() async {
    final (destinations, problem) = _collectDestinations();
    if (problem != null) {
      setState(() => errorMessage = problem);
      return;
    }

    setState(() {
      submitting = true;
      errorMessage = null;
    });
    final error = await controller.finish(
      widget.board,
      ending: widget.ending,
      destinations: destinations,
      paidValues: registerValues ? paid : const {},
    );
    if (!mounted) return;
    setState(() {
      submitting = false;
      errorMessage = error;
    });
    if (error != null) return;

    Navigator.of(context).pop();
    final pendingCount = destinations.values.where((d) => d.toBoardId == null).length;
    final moved = destinations.length - pendingCount;
    final details = [
      'Está no Histórico.',
      if (moved > 0) '$moved ${moved == 1 ? 'item foi' : 'itens foram'} para outro quadro.',
      if (pendingCount > 0) '$pendingCount ${pendingCount == 1 ? 'item foi' : 'itens foram'} para Pendências.',
    ].join(' ');
    AppFeedback.success(details, title: isCancel ? 'Quadro cancelado' : 'Quadro finalizado');
  }

  void _setAll(String target) {
    setState(() {
      for (final item in unpurchased) {
        destination[item.id] = target;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final progress = controller.progressOf(widget.board);
    final extra = registerValues ? paid.values.fold(Money.zero, (sum, v) => sum + v) : Money.zero;
    final spent = progress.purchased + extra;

    final rows = <(String, String, Color?)>[
      ('Comprados', '${progress.purchasedCount} de ${progress.itemCount}', null),
      ('Total gasto', spent.formatted, null),
      if (progress.hasGoal) ('Meta', progress.goal!.formatted, null),
      if (progress.hasGoal)
        spent > progress.goal!
            ? ('Acima da meta', (spent - progress.goal!).formatted, context.colors.error)
            : ('Abaixo da meta', (progress.goal! - spent).formatted, context.semantic.success),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading(
            isCancel ? 'Cancelar "${widget.board.title}"?' : 'Finalizar "${widget.board.title}"?',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            isCancel
                ? 'O quadro vai para o Histórico como cancelado e não pode ser reaberto. '
                    'O que já foi comprado continua nos relatórios.'
                : 'O quadro vai para o Histórico e não pode ser reaberto. '
                    'Você ainda poderá ajustar datas e valores das compras por lá.',
            color: secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryBox(rows: rows),
          if (unpurchased.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(
              icon: Symbols.remove_shopping_cart,
              title: 'Não comprados (${unpurchased.length})',
              subtitle: otherBoards.isEmpty
                  ? 'Não há outro quadro aberto, então eles vão para Pendências. Conte o motivo.'
                  : 'Escolha para onde vai cada item.',
            ),
            if (otherBoards.isNotEmpty && unpurchased.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              _DestinationField(
                label: 'Enviar todos para…',
                boards: otherBoards,
                value: null,
                onChanged: (v) => v == null ? null : _setAll(v),
              ),
            ],
            for (final item in unpurchased) ...[
              const SizedBox(height: AppSpacing.sm),
              _UnpurchasedTile(
                item: item,
                boards: otherBoards,
                destination: destination[item.id],
                reason: reason[item.id],
                otherReasonController: reason[item.id] == _otherReason ? _otherReasonOf(item.id) : null,
                onDestination: (v) => setState(() => destination[item.id] = v),
                onReason: (v) => setState(() => reason[item.id] = v),
              ),
            ],
          ],
          if (withoutValue.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(
              icon: Symbols.payments,
              title: 'Comprados sem valor (${withoutValue.length})',
              subtitle: 'Sem valor, eles entram com R\$ 0,00 nos relatórios.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Informar quanto paguei'),
              value: registerValues,
              onChanged: (v) => setState(() => registerValues = v),
            ),
            if (registerValues)
              for (final item in withoutValue)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppMoneyField(
                    label: item.title,
                    onChanged: (v) => setState(() => v.isZero ? paid.remove(item.id) : paid[item.id] = v),
                  ),
                ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(errorMessage!, color: context.colors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(label: 'Voltar', onPressed: () => Navigator.of(context).pop()),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: isCancel
                    ? AppButton.danger(label: 'Cancelar quadro', onPressed: submitting ? null : _submit)
                    : AppButton(label: 'Finalizar', onPressed: submitting ? null : _submit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final List<(String, String, Color?)> rows;
  const _SummaryBox({required this.rows});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: context.colors.surfaceContainerHighest, borderRadius: AppRadius.borderMd),
      child: Column(
        children: [
          for (final (label, value, color) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: AppText.small(label, color: secondary)),
                  AppText.small(value, fontWeight: FontWeight.bold, color: color),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionTitle({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(title, fontWeight: FontWeight.bold),
              AppText.subtitle(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationField extends StatelessWidget {
  final String label;
  final List<PlanBoardEntity> boards;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DestinationField({required this.label, required this.boards, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // Recria o campo quando o valor muda por fora ("Enviar todos para…").
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        for (final b in boards)
          DropdownMenuItem(
            value: b.id,
            child: Row(
              children: [
                const Icon(Symbols.view_kanban, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(b.title, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        const DropdownMenuItem(
          value: _toPending,
          child: Row(
            children: [
              Icon(Symbols.pending_actions, size: 18),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Pendências (não comprei)', overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _UnpurchasedTile extends StatelessWidget {
  final PlanItemEntity item;
  final List<PlanBoardEntity> boards;
  final String? destination;
  final String? reason;
  final TextEditingController? otherReasonController;
  final ValueChanged<String?> onDestination;
  final ValueChanged<String> onReason;

  const _UnpurchasedTile({
    required this.item,
    required this.boards,
    required this.destination,
    required this.reason,
    required this.otherReasonController,
    required this.onDestination,
    required this.onReason,
  });

  @override
  Widget build(BuildContext context) {
    final value = item.value;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppText(item.title, fontWeight: FontWeight.w600, maxLines: 2)),
              AppText.subtitle(value?.formatted ?? 'Sem valor'),
            ],
          ),
          if (boards.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DestinationField(label: 'Destino', boards: boards, value: destination, onChanged: onDestination),
          ],
          if (destination == _toPending) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText.subtitle('Por que não comprou?'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final r in notPurchasedReasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: reason == r,
                    onSelected: (_) => onReason(r),
                  ),
              ],
            ),
            if (otherReasonController != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: otherReasonController!,
                label: 'Motivo',
                hint: 'Ex.: loja fechada',
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
