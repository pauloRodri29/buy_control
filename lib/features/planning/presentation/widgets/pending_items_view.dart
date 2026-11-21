import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_board_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

enum _PendingAction { send, delete }

/// Aba Pendências: itens que não foram comprados quando o quadro foi
/// finalizado. Ficam aqui até irem para um quadro (deslizar para a
/// esquerda) ou serem excluídos (deslizar para a direita).
class PendingItemsView extends StatefulWidget {
  const PendingItemsView({super.key});

  @override
  State<PendingItemsView> createState() => _PendingItemsViewState();
}

class _PendingItemsViewState extends State<PendingItemsView> {
  PlanningController get _controller => Get.find<PlanningController>();

  /// Itens já resolvidos que somem da lista na hora, antes de o controller
  /// recarregar (o [Dismissible] exige sair da árvore imediatamente).
  final _resolved = <String>{};

  Future<bool> _delete(PlanItemEntity item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir "${item.title}"?',
      message: 'A pendência será removida. Esta ação não pode ser desfeita.',
    );
    if (!confirmed) return false;
    final error = await _controller.removeItem(item.id);
    if (error != null) {
      AppFeedback.error(error, title: 'Não foi possível excluir');
      return false;
    }
    setState(() => _resolved.add(item.id));
    return true;
  }

  Future<bool> _sendToBoard(PlanItemEntity item) async {
    final boards = _controller.activeBoards;
    if (boards.isEmpty) {
      AppFeedback.info('Crie um quadro na aba Quadros para enviar este item.', title: 'Nenhum quadro aberto');
      return false;
    }
    final board = await showPlanBoardPicker(context, title: 'Enviar "${item.title}" para', boards: boards);
    if (board == null || !mounted) return false;

    final error = await _controller.sendPendingTo(item, board.id);
    if (error != null) {
      AppFeedback.error(error, title: 'Não foi possível enviar');
      return false;
    }
    setState(() => _resolved.add(item.id));
    AppFeedback.success('"${item.title}" voltou para "${board.title}".', title: 'Item enviado');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlanningController>(
      builder: (controller) {
        final items = controller.pendingItems.where((i) => !_resolved.contains(i.id)).toList();
        if (items.isEmpty) {
          return const EmptyStateView(
            icon: Symbols.pending_actions,
            title: 'Nenhuma pendência',
            message: 'Itens que não foram comprados quando você finaliza um quadro aparecem aqui, '
                'com o motivo, até você mandá-los para outro quadro.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            if (i == 0) return const _SwipeHint();
            final item = items[i - 1];
            return _PendingDismissible(
              item: item,
              originTitle: controller.boardById(item.boardId)?.title,
              originDate: controller.boardById(item.boardId)?.finishedAt,
              onDelete: () => _delete(item),
              onSend: () => _sendToBoard(item),
            );
          },
        );
      },
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    return Row(
      children: [
        Icon(Symbols.swipe, size: 16, color: secondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppText.subtitle('Deslize para a esquerda para enviar a um quadro, ou para a direita para excluir.'),
        ),
      ],
    );
  }
}

class _PendingDismissible extends StatelessWidget {
  final PlanItemEntity item;
  final String? originTitle;
  final DateTime? originDate;
  final Future<bool> Function() onDelete;
  final Future<bool> Function() onSend;

  const _PendingDismissible({
    required this.item,
    required this.originTitle,
    required this.originDate,
    required this.onDelete,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      // Para a direita: excluir.
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: context.colors.error,
        foreground: context.colors.onError,
        icon: Symbols.delete,
        label: 'Excluir',
      ),
      // Para a esquerda: enviar para um quadro.
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: context.colors.primary,
        foreground: context.colors.onPrimary,
        icon: Symbols.view_kanban,
        label: 'Enviar para quadro',
      ),
      confirmDismiss: (direction) =>
          direction == DismissDirection.startToEnd ? onDelete() : onSend(),
      child: _PendingCard(
        item: item,
        originTitle: originTitle,
        originDate: originDate,
        onAction: (action) => switch (action) {
          _PendingAction.send => onSend(),
          _PendingAction.delete => onDelete(),
        },
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, color: foreground),
      const SizedBox(width: AppSpacing.sm),
      AppText(label, color: foreground, fontWeight: FontWeight.bold),
    ];
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.borderMd),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerRight ? children.reversed.toList() : children,
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PlanItemEntity item;
  final String? originTitle;
  final DateTime? originDate;
  final ValueChanged<_PendingAction> onAction;

  const _PendingCard({required this.item, required this.originTitle, required this.originDate, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final value = item.value;
    final origin = [
      if (originTitle != null) 'De "$originTitle"',
      if (originDate != null) DateTimeFormatter.ddMMyyyy(originDate!),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(item.title, fontWeight: FontWeight.w600, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Symbols.info, size: 14, color: context.semantic.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText.small(item.notPurchasedReason ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (origin.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText.subtitle(origin, color: secondary),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: AppText.small(
              value?.formatted ?? 'Sem valor',
              fontWeight: value == null ? FontWeight.normal : FontWeight.bold,
              color: value == null ? secondary : null,
            ),
          ),
          PopupMenuButton<_PendingAction>(
            icon: Icon(Symbols.more_vert, size: 18, color: secondary),
            onSelected: onAction,
            itemBuilder: (_) => const [
              PopupMenuItem(value: _PendingAction.send, child: Text('Enviar para quadro…')),
              PopupMenuItem(value: _PendingAction.delete, child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
