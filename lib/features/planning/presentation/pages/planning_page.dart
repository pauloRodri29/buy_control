import 'dart:async';

import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/state/view_status.dart';
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
import 'package:buy_control/features/planning/domain/usecases/plan_board_usecases.dart';
import 'package:buy_control/features/planning/presentation/widgets/finish_plan_board_sheet.dart';
import 'package:buy_control/features/planning/presentation/widgets/pending_items_view.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_history_view.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_board_form_sheet.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_column.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_item_card.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_item_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

enum _MenuOption { toggleArchived, togglePurchased }

enum _DeleteBoardChoice { moveItems, deleteItems }

/// Planejamento de compras, em três abas:
/// - Quadros: kanban dos quadros abertos. A primeira coluna é "Sem quadro"
///   (quando há itens soltos); as demais são os quadros, ordenados pela
///   data de previsão.
/// - Pendências: itens não comprados de quadros já finalizados.
/// - Histórico: quadros finalizados ou cancelados (sem reabrir).
class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  PlanningController get _controller => Get.find<PlanningController>();

  void _showError(String? error) {
    if (error != null) AppFeedback.error(error, title: 'common.couldntComplete'.tr);
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
      case PlanBoardAction.finish:
        AppBottomSheet.show(context, child: FinishPlanBoardSheet(board: board));
      case PlanBoardAction.cancel:
        AppBottomSheet.show(context, child: FinishPlanBoardSheet(board: board, ending: PlanBoardEnding.cancel));
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
        title: 'planning.deleteBoardTitle'.trParams({'title': board.title}),
        message: 'planning.boardEmptyActionCantUndone'.tr,
      );
      if (confirmed) _showError(await _controller.removeBoard(board.id, deleteItems: false));
      return;
    }

    final choice = await showDialog<_DeleteBoardChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('planning.deleteBoardTitle'.trParams({'title': board.title})),
        content: Text(
          'planning.boardHasYouCanKeepCountValue'.trParams({'count': '$count', 'value': count == 1 ? 'common.item'.tr : 'common.items'.tr}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('common.cancel'.tr)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_DeleteBoardChoice.moveItems),
            child: Text('planning.keepItems'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_DeleteBoardChoice.deleteItems),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text('planning.deleteEverything'.tr),
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
          title: 'planning.deleteTitle'.trParams({'title': item.title}),
          message: 'planning.itemWillRemovedFromPlanning'.tr,
        );
        if (confirmed) _showError(await _controller.removeItem(item.id));
    }
  }

  Future<void> _showMoveSheet(BuildContext context, PlanItemEntity item) async {
    final destinations = <({String? id, String title, String? subtitle})>[
      (id: null, title: 'common.noBoard'.tr, subtitle: null),
      for (final b in _controller.activeBoards)
        (id: b.id, title: b.title, subtitle: DateTimeFormatter.ddMMyyyy(b.targetDate)),
    ];

    await AppBottomSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading('planning.moveTitle'.trParams({'title': item.title}),  maxLines: 2),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final d in destinations)
                  Builder(builder: (tileContext) {
                    final isCurrent = d.id == item.boardId;
                    return ListTile(
                      leading: Icon(d.id == null ? Symbols.inbox : Symbols.view_kanban),
                      title: AppText(d.title, fontWeight: FontWeight.w600),
                      subtitle: d.subtitle == null
                          ? null
                          : AppText.subtitle(d.subtitle!),
                      trailing: isCurrent ? Icon(Symbols.check_circle, fill: 1, color: context.colors.primary) : null,
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
    return DefaultTabController(
      length: 3,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.heading('common.planning'.tr),
        bottom: const _PlanningTabBar(),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            tooltip: 'planning.newBoard'.tr,
            onPressed: () => _openBoardForm(context),
          ),
          GetBuilder<PlanningController>(
            builder: (controller) => PopupMenuButton<_MenuOption>(
              icon: const Icon(Symbols.more_vert),
              onSelected: (option) => switch (option) {
                _MenuOption.toggleArchived => controller.toggleShowArchived(),
                _MenuOption.togglePurchased => controller.toggleHidePurchased(),
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: _MenuOption.toggleArchived,
                  checked: controller.showArchived,
                  child: Text('planning.showArchived'.tr),
                ),
                CheckedPopupMenuItem(
                  value: _MenuOption.togglePurchased,
                  checked: controller.hidePurchased,
                  child: Text('planning.hidePurchased'.tr),
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
              return ErrorStateView(message: controller.errorMessage ?? 'common.unexpectedError'.tr, onRetry: controller.load);
            case ViewStatus.empty:
            case ViewStatus.success:
              return TabBarView(
                // Sem troca de aba por gesto: o kanban rola na horizontal e
                // as Pendências usam deslizar para os lados.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  controller.isKanbanEmpty
                      ? EmptyStateView(
                          icon: Symbols.view_kanban,
                          title: 'planning.planNextPurchases'.tr,
                          message: 'planning.createBoardsLikeDecemberYear'.tr,
                          actionLabel: 'planning.newBoard'.tr,
                          onAction: () => _openBoardForm(context),
                        )
                      : _buildBoard(context, controller),
                  const PendingItemsView(),
                  const PlanHistoryView(),
                ],
              );
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
          locked: board != null && controller.isLocked(board.id),
          lockedItemIds: controller.lockedItemIds,
          onLockedTap: controller.showLockedPrompt,
        );
      },
    );
  }
}

/// Abas do Planejamento; "Pendências" mostra a quantidade em aberto.
class _PlanningTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _PlanningTabBar();

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlanningController>(
      builder: (controller) {
        final pending = controller.pendingItems.length;
        return TabBar(
          labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tabs: [
            Tab(text: 'planning.boards'.tr),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text('planning.pending'.tr, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (pending > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Badge.count(count: pending),
                  ],
                ],
              ),
            ),
            Tab(text: 'common.history'.tr),
          ],
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
  static const _singleMaxWidth = 560.0;
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
        const padding = EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg);

        // Um único quadro ocupa a largura disponível (limitada em telas
        // largas) e fica centralizado, em vez de encostar à esquerda.
        if (widget.itemCount == 1) {
          final width = (constraints.maxWidth - padding.horizontal).clamp(0.0, _singleMaxWidth);
          return Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.topCenter,
              child: widget.columnBuilder(context, 0, width, (_) {}, () {}),
            ),
          );
        }

        final width = (constraints.maxWidth * 0.85).clamp(260.0, 360.0);
        return ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, i) => widget.columnBuilder(context, i, width, _onDragUpdate, _stop),
        );
      },
    );
  }
}
