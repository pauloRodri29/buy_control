import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_progress.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_item_card.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PlanBoardAction { edit, finish, cancel, archive, unarchive, delete }

/// Coluna do kanban: um quadro (ou "Sem quadro" quando [board] é `null`).
/// Aceita itens arrastados: soltar sobre um card insere antes dele; soltar
/// no espaço livre da coluna coloca no final.
class PlanColumn extends StatelessWidget {
  final PlanBoardEntity? board;
  final List<PlanItemEntity> items;
  final PlanBoardProgress progress;
  final double width;
  final VoidCallback onAddItem;
  final ValueChanged<PlanBoardAction> onBoardAction;
  final ValueChanged<PlanItemEntity> onEditItem;
  final ValueChanged<PlanItemEntity> onTogglePurchased;
  final void Function(PlanItemEntity item, PlanItemAction action) onItemAction;
  final void Function(PlanItemEntity item, String? beforeItemId) onDropItem;

  /// Posição global do dedo enquanto um item é arrastado (rolagem
  /// automática do quadro) e fim do arraste.
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;

  const PlanColumn({
    super.key,
    required this.board,
    required this.items,
    required this.progress,
    required this.width,
    required this.onAddItem,
    required this.onBoardAction,
    required this.onEditItem,
    required this.onTogglePurchased,
    required this.onItemAction,
    required this.onDropItem,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlanItemEntity>(
      onAcceptWithDetails: (details) => onDropItem(details.data, null),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: highlighted ? context.colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(board: board, progress: progress, onAction: onBoardAction),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: AppText.subtitle(
                            board == null
                                ? 'Itens sem contexto ficam aqui. Arraste-os para um quadro.'
                                : 'Nenhum item ainda.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) => _DraggableItem(
                          item: items[i],
                          width: width - AppSpacing.lg,
                          onEdit: () => onEditItem(items[i]),
                          onTogglePurchased: () => onTogglePurchased(items[i]),
                          onAction: (action) => onItemAction(items[i], action),
                          onDropBefore: (dragged) => onDropItem(dragged, items[i].id),
                          onDragUpdate: onDragUpdate,
                          onDragEnd: onDragEnd,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Adicionar item'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableItem extends StatelessWidget {
  final PlanItemEntity item;
  final double width;
  final VoidCallback onEdit;
  final VoidCallback onTogglePurchased;
  final ValueChanged<PlanItemAction> onAction;
  final ValueChanged<PlanItemEntity> onDropBefore;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;

  const _DraggableItem({
    required this.item,
    required this.width,
    required this.onEdit,
    required this.onTogglePurchased,
    required this.onAction,
    required this.onDropBefore,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final card = PlanItemCard(item: item, onTap: onEdit, onTogglePurchased: onTogglePurchased, onAction: onAction);

    return DragTarget<PlanItemEntity>(
      onWillAcceptWithDetails: (details) => details.data.id != item.id,
      onAcceptWithDetails: (details) => onDropBefore(details.data),
      builder: (context, candidates, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de onde o item arrastado vai entrar.
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: candidates.isNotEmpty ? 4 : 0,
              margin: EdgeInsets.only(bottom: candidates.isNotEmpty ? AppSpacing.xs : 0),
              decoration: BoxDecoration(color: context.colors.primary, borderRadius: AppRadius.borderSm),
            ),
            LongPressDraggable<PlanItemEntity>(
              data: item,
              hapticFeedbackOnStart: true,
              onDragUpdate: (details) => onDragUpdate?.call(details.globalPosition),
              onDragEnd: (_) => onDragEnd?.call(),
              feedback: Material(
                color: Colors.transparent,
                elevation: 6,
                child: SizedBox(width: width, child: PlanItemCard(item: item)),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: card),
              child: card,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final PlanBoardEntity? board;
  final PlanBoardProgress progress;
  final ValueChanged<PlanBoardAction> onAction;

  const _Header({required this.board, required this.progress, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final board = this.board;
    final overdue = board != null && board.isOverdue(DateTime.now());
    final allPurchased = board != null && progress.itemCount > 0 && progress.purchasedCount == progress.itemCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (board == null) ...[
                Icon(Symbols.inbox, size: 18, color: secondary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: AppText(
                  board?.title ?? 'Sem quadro',
                  
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (board != null)
                PopupMenuButton<PlanBoardAction>(
                  icon: Icon(Symbols.more_vert, size: 18, color: secondary),
                  onSelected: onAction,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: PlanBoardAction.edit, child: Text('Editar quadro')),
                    const PopupMenuItem(value: PlanBoardAction.finish, child: Text('Finalizar quadro')),
                    const PopupMenuItem(value: PlanBoardAction.cancel, child: Text('Cancelar quadro')),
                    board.isArchived
                        ? const PopupMenuItem(value: PlanBoardAction.unarchive, child: Text('Desarquivar'))
                        : const PopupMenuItem(value: PlanBoardAction.archive, child: Text('Arquivar')),
                    const PopupMenuItem(value: PlanBoardAction.delete, child: Text('Excluir quadro')),
                  ],
                )
              else
                const SizedBox(height: 40),
            ],
          ),
          if (board != null) ...[
            Row(
              children: [
                Icon(Symbols.event, size: 14, color: overdue ? context.colors.error : secondary),
                const SizedBox(width: AppSpacing.xs),
                AppText.subtitle(
                  overdue
                      ? '${DateTimeFormatter.ddMMyyyy(board.targetDate)} · atrasado'
                      : DateTimeFormatter.ddMMyyyy(board.targetDate),
                  color: overdue ? context.colors.error : secondary,
                ),
                if (board.isArchived) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Symbols.archive, size: 14, color: secondary),
                  const SizedBox(width: AppSpacing.xs),
                  AppText.subtitle('Arquivado', color: secondary),
                ],
              ],
            ),
            if (board.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText.subtitle(board.description!, color: secondary, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _ProgressSummary(progress: progress),
          ),
          if (allPurchased) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FinishBanner(onFinish: () => onAction(PlanBoardAction.finish)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final PlanBoardProgress progress;
  const _ProgressSummary({required this.progress});

  Color _barColor(BuildContext context) {
    final ratio = progress.goalRatio ?? 0;
    if (progress.isOverGoal) return context.colors.error;
    if (ratio >= 0.9) return context.semantic.warning;
    return context.colors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;

    final counts = '${progress.purchasedCount}/${progress.itemCount} comprados'
        '${progress.itemsWithoutValue > 0 ? ' · ${progress.itemsWithoutValue} sem valor' : ''}';

    if (!progress.hasGoal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.small('Planejado: ${progress.planned.formatted}',  fontWeight: FontWeight.w600),
          AppText.subtitle(counts, color: secondary),
        ],
      );
    }

    final remaining = progress.remaining!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Symbols.track_changes, size: 14, color: _barColor(context)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppText.small(
                '${progress.planned.formatted} de ${progress.goal!.formatted}',
                
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.borderSm,
          child: LinearProgressIndicator(
            value: (progress.goalRatio ?? 0).clamp(0, 1).toDouble(),
            minHeight: 6,
            color: _barColor(context),
            backgroundColor: context.colors.outlineVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppText.subtitle(
          progress.isOverGoal
              ? '${(progress.planned - progress.goal!).formatted} acima da meta'
              : 'Ainda cabe ${remaining.formatted}',
          color: progress.isOverGoal ? context.colors.error : secondary,
        ),
        AppText.subtitle(counts, color: secondary),
      ],
    );
  }
}

/// Aparece quando todos os itens do quadro foram comprados.
class _FinishBanner extends StatelessWidget {
  final VoidCallback onFinish;
  const _FinishBanner({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final success = context.semantic.success;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Symbols.task_alt, size: 18, color: success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppText.small('Tudo comprado!', fontWeight: FontWeight.bold, color: success)),
          FilledButton.tonalIcon(
            onPressed: onFinish,
            icon: const Icon(Symbols.flag, size: 18),
            label: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}
