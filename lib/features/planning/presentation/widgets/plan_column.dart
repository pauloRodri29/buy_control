import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_progress.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:buy_control/features/planning/presentation/widgets/plan_item_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum PlanBoardAction { edit, close, reopen, archive, unarchive, delete }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DragTarget<PlanItemEntity>(
      onAcceptWithDetails: (details) => onDropItem(details.data, null),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant(isDark),
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: highlighted ? AppColors.accent : Colors.transparent,
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
                            color: AppColors.textSecondary(isDark),
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
                  icon: const Icon(LucideIcons.plus, size: 18),
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
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.borderSm),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = AppColors.textSecondary(isDark);
    final board = this.board;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (board == null) ...[
                Icon(LucideIcons.inbox, size: 18, color: secondary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: AppText(
                  board?.title ?? 'Sem quadro',
                  fontSize: AppFontSizes.fz08,
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (board != null)
                PopupMenuButton<PlanBoardAction>(
                  icon: Icon(LucideIcons.ellipsisVertical, size: 18, color: secondary),
                  onSelected: onAction,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: PlanBoardAction.edit, child: Text('Editar quadro')),
                    board.isClosed
                        ? const PopupMenuItem(value: PlanBoardAction.reopen, child: Text('Reabrir quadro'))
                        : const PopupMenuItem(value: PlanBoardAction.close, child: Text('Fechar quadro')),
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
                Icon(LucideIcons.calendarClock, size: 14, color: secondary),
                const SizedBox(width: AppSpacing.xs),
                AppText.subtitle(DateTimeFormatter.ddMMyyyy(board.targetDate), color: secondary),
                if (board.isArchived) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(LucideIcons.archive, size: 14, color: secondary),
                  const SizedBox(width: AppSpacing.xs),
                  AppText.subtitle('Arquivado', color: secondary),
                ],
              ],
            ),
            if (board.isClosed) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(LucideIcons.badgeCheck, size: 14, color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  AppText.subtitle(
                    'Fechado em ${DateTimeFormatter.ddMMyyyy(board.closedAt!)}',
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
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
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final PlanBoardProgress progress;
  const _ProgressSummary({required this.progress});

  Color _barColor() {
    final ratio = progress.goalRatio ?? 0;
    if (progress.isOverGoal) return AppColors.error;
    if (ratio >= 0.9) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = AppColors.textSecondary(isDark);

    final counts = '${progress.purchasedCount}/${progress.itemCount} comprados'
        '${progress.itemsWithoutValue > 0 ? ' · ${progress.itemsWithoutValue} sem valor' : ''}';

    if (!progress.hasGoal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText('Planejado: ${progress.planned.formatted}', fontSize: AppFontSizes.fz06, fontWeight: FontWeight.w600),
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
            Icon(LucideIcons.target, size: 14, color: _barColor()),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppText(
                '${progress.planned.formatted} de ${progress.goal!.formatted}',
                fontSize: AppFontSizes.fz06,
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
            color: _barColor(),
            backgroundColor: AppColors.border(isDark),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppText.subtitle(
          progress.isOverGoal
              ? '${(progress.planned - progress.goal!).formatted} acima da meta'
              : 'Ainda cabe ${remaining.formatted}',
          color: progress.isOverGoal ? AppColors.error : secondary,
        ),
        AppText.subtitle(counts, color: secondary),
      ],
    );
  }
}
