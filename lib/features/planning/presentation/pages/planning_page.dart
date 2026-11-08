import 'dart:async';

import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:buy_control/features/planning/presentation/widgets/close_plan_board_sheet.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_board_form_sheet.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_column.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_item_card.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_item_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _MenuOption { toggleArchived, togglePurchased }

enum _DeleteBoardChoice { moveItems, deleteItems }

/// Planejamento de compras em quadros estilo kanban. A primeira coluna é
/// "Sem quadro" (quando há itens soltos); as demais são os quadros,
/// ordenados pela data de previsão.
class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  PlanningController get _controller => Get.find<PlanningController>();

  void _showError(String? error) {
    if (error != null) Get.snackbar('Não foi possível concluir', error);
  }

  void _openBoardForm(BuildContext context, {PlanBoardEntity? board}) {
    AppBottomSheet.show(context, child: PlanBoardFormSheet(board: board));
  }

  void _openItemForm(BuildContext context, {PlanItemEntity? item, String? boardId}) {
    AppBottomSheet.show(context, child: PlanItemFormSheet(item: item, initialBoardId: boardId));
  }

  Future<void> _onBoardAction(BuildContext context, PlanBoardEntity board, PlanBoardAction action) async {
    switch (action) {
      case PlanBoardAction.edit:
        _openBoardForm(context, board: board);
      case PlanBoardAction.close:
        AppBottomSheet.show(context, child: ClosePlanBoardSheet(board: board));
      case PlanBoardAction.reopen:
        final confirmed = await ConfirmDialog.show(
          context,
          title: 'Reabrir "${board.title}"?',
          message: 'O quadro volta a ficar em aberto. Os itens continuam marcados como comprados e '
              'nos relatórios; desmarque os que não foram comprados de fato.',
          confirmLabel: 'Reabrir',
          isDestructive: false,
        );
        if (confirmed) _showError(await _controller.reopen(board));
      case PlanBoardAction.archive:
        _showError(await _controller.setArchived(board, true));
      case PlanBoardAction.unarchive:
        _showError(await _controller.setArchived(board, false));
      case PlanBoardAction.delete:
        await _deleteBoard(context, board);
    }
  }

  Future<void> _deleteBoard(BuildContext context, PlanBoardEntity board) async {
    final count = _controller.itemCountOf(board.id);

    if (count == 0) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Excluir o quadro "${board.title}"?',
        message: 'O quadro está vazio. Esta ação não pode ser desfeita.',
      );
      if (confirmed) _showError(await _controller.removeBoard(board.id, deleteItems: false));
      return;
    }

    final choice = await showDialog<_DeleteBoardChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Excluir o quadro "${board.title}"?'),
        content: Text(
          'Este quadro tem $count ${count == 1 ? 'item' : 'itens'}. Você pode mantê-los em '
          '"Sem quadro" ou excluí-los junto. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_DeleteBoardChoice.moveItems),
            child: const Text('Manter itens'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_DeleteBoardChoice.deleteItems),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    _showError(await _controller.removeBoard(board.id, deleteItems: choice == _DeleteBoardChoice.deleteItems));
  }

  Future<void> _onItemAction(BuildContext context, PlanItemEntity item, PlanItemAction action) async {
    switch (action) {
      case PlanItemAction.edit:
        _openItemForm(context, item: item);
      case PlanItemAction.move:
        await _showMoveSheet(context, item);
      case PlanItemAction.delete:
        final confirmed = await ConfirmDialog.show(
          context,
          title: 'Excluir "${item.title}"?',
          message: 'O item será removido do planejamento. Esta ação não pode ser desfeita.',
        );
        if (confirmed) _showError(await _controller.removeItem(item.id));
    }
  }

  Future<void> _showMoveSheet(BuildContext context, PlanItemEntity item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final destinations = <({String? id, String title, String? subtitle})>[
      (id: null, title: 'Sem quadro', subtitle: null),
      for (final b in _controller.activeBoards)
        (id: b.id, title: b.title, subtitle: DateTimeFormatter.ddMMyyyy(b.targetDate)),
    ];

    await AppBottomSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title('Mover "${item.title}" para', fontSize: AppFontSizes.fz09, maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final d in destinations)
                  Builder(builder: (tileContext) {
                    final isCurrent = d.id == item.boardId;
                    return ListTile(
                      leading: Icon(d.id == null ? LucideIcons.inbox : LucideIcons.squareKanban),
                      title: AppText(d.title, fontWeight: FontWeight.w600),
                      subtitle: d.subtitle == null
                          ? null
                          : AppText.subtitle(d.subtitle!, color: AppColors.textSecondary(isDark)),
                      trailing: isCurrent ? const Icon(LucideIcons.circleCheck, color: AppColors.accent) : null,
                      onTap: () async {
                        Navigator.of(tileContext).pop();
                        if (!isCurrent) _showError(await _controller.move(item, toBoardId: d.id));
                      },
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText.title('Planejamento', fontSize: AppFontSizes.fz09),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Novo quadro',
            onPressed: () => _openBoardForm(context),
          ),
          GetBuilder<PlanningController>(
            builder: (controller) => PopupMenuButton<_MenuOption>(
              icon: const Icon(LucideIcons.ellipsisVertical),
              onSelected: (option) => switch (option) {
                _MenuOption.toggleArchived => controller.toggleShowArchived(),
                _MenuOption.togglePurchased => controller.toggleHidePurchased(),
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: _MenuOption.toggleArchived,
                  checked: controller.showArchived,
                  child: const Text('Mostrar arquivados'),
                ),
                CheckedPopupMenuItem(
                  value: _MenuOption.togglePurchased,
                  checked: controller.hidePurchased,
                  child: const Text('Ocultar comprados'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: GetBuilder<PlanningController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: LucideIcons.squareKanban,
                title: 'Planeje suas próximas compras',
                message: 'Crie quadros como "Dezembro" ou "Fim de ano", defina uma data de previsão e uma '
                    'meta de gasto, e adicione os itens que pretende comprar.',
                actionLabel: 'Novo quadro',
                onAction: () => _openBoardForm(context),
              );
            case ViewStatus.success:
              return _buildBoard(context, controller);
          }
        },
      ),
    );
  }

  Widget _buildBoard(BuildContext context, PlanningController controller) {
    final showInbox = controller.hasInboxItems || controller.boards.isEmpty;
    final columns = <PlanBoardEntity?>[if (showInbox) null, ...controller.boards];

    return _KanbanScroller(
      itemCount: columns.length,
      columnBuilder: (context, i, width, onDragUpdate, onDragEnd) {
        final board = columns[i];
        return PlanColumn(
          key: ValueKey(board?.id ?? '__inbox__'),
          board: board,
          items: controller.itemsOf(board?.id),
          progress: controller.progressOf(board),
          width: width,
          onAddItem: () => _openItemForm(context, boardId: board?.id),
          onBoardAction: (action) => _onBoardAction(context, board!, action),
          onEditItem: (item) => _openItemForm(context, item: item),
          onTogglePurchased: (item) async => _showError(await controller.togglePurchasedOf(item)),
          onItemAction: (item, action) => _onItemAction(context, item, action),
          onDropItem: (item, beforeId) async =>
              _showError(await controller.move(item, toBoardId: board?.id, beforeItemId: beforeId)),
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
        );
      },
    );
  }
}

typedef _ColumnBuilder = Widget Function(
  BuildContext context,
  int index,
  double width,
  ValueChanged<Offset> onDragUpdate,
  VoidCallback onDragEnd,
);

/// Lista horizontal de colunas com rolagem automática: enquanto um item é
/// arrastado perto da borda esquerda/direita, a lista rola sozinha para
/// alcançar os outros quadros. Quanto mais perto da borda, mais rápido.
class _KanbanScroller extends StatefulWidget {
  final int itemCount;
  final _ColumnBuilder columnBuilder;

  const _KanbanScroller({required this.itemCount, required this.columnBuilder});

  @override
  State<_KanbanScroller> createState() => _KanbanScrollerState();
}

class _KanbanScrollerState extends State<_KanbanScroller> {
  static const _edge = 80.0;
  static const _maxSpeed = 20.0;
  static const _tick = Duration(milliseconds: 16);

  final _scrollController = ScrollController();
  Timer? _timer;
  double _speed = 0;

  @override
  void dispose() {
    _stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragUpdate(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final dx = box.globalToLocal(globalPosition).dx;
    final width = box.size.width;

    if (dx < _edge) {
      _speed = -_maxSpeed * ((_edge - dx) / _edge).clamp(0.25, 1.0);
    } else if (dx > width - _edge) {
      _speed = _maxSpeed * ((dx - (width - _edge)) / _edge).clamp(0.25, 1.0);
    } else {
      _speed = 0;
    }

    if (_speed == 0) {
      _stop();
    } else {
      _timer ??= Timer.periodic(_tick, (_) => _step());
    }
  }

  void _step() {
    if (!_scrollController.hasClients || _speed == 0) return;
    final position = _scrollController.position;
    final target = (position.pixels + _speed).clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) _scrollController.jumpTo(target);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _speed = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.85).clamp(260.0, 360.0);
        return ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          itemCount: widget.itemCount,
          itemBuilder: (context, i) => widget.columnBuilder(context, i, width, _onDragUpdate, _stop),
        );
      },
    );
  }
}
