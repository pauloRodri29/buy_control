import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_progress.dart';
import 'package:buy_control/features/planning/presentation/controllers/planning_controller.dart';
import 'package:buy_control/features/planning/presentation/pages/plan_board_history_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Aba Histórico: quadros finalizados e cancelados, do mais recente para
/// o mais antigo.
class PlanHistoryView extends StatelessWidget {
  const PlanHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlanningController>(
      builder: (controller) {
        final boards = controller.history;
        if (boards.isEmpty) {
          return const EmptyStateView(
            icon: Symbols.history,
            title: 'Nada no histórico ainda',
            message: 'Quando você finalizar ou cancelar um quadro, ele aparece aqui com o resumo do que '
                'foi gasto.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          itemCount: boards.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final board = boards[i];
            return PlanHistoryCard(
              board: board,
              progress: controller.historyProgressOf(board),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PlanBoardHistoryPage(boardId: board.id)),
              ),
            );
          },
        );
      },
    );
  }
}

/// Selo "Finalizado"/"Cancelado" de um quadro do Histórico.
class PlanBoardStatusChip extends StatelessWidget {
  final PlanBoardEntity board;
  const PlanBoardStatusChip({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    final cancelled = board.isCancelled;
    final color = cancelled ? context.colors.onSurfaceVariant : context.semantic.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cancelled ? Symbols.block : Symbols.task_alt, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          AppText.small(cancelled ? 'Cancelado' : 'Finalizado', color: color, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}

class PlanHistoryCard extends StatelessWidget {
  final PlanBoardEntity board;
  final PlanBoardProgress progress;
  final VoidCallback onTap;

  const PlanHistoryCard({super.key, required this.board, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final spent = progress.purchased;
    final goal = progress.goal;

    return Material(
      color: context.colors.surfaceContainerHighest,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(board.title, fontWeight: FontWeight.bold, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PlanBoardStatusChip(board: board),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText.subtitle(
                '${board.isCancelled ? 'Cancelado' : 'Finalizado'} em ${DateTimeFormatter.ddMMyyyy(board.finishedAt!)}'
                ' · previsão ${DateTimeFormatter.ddMMyyyy(board.targetDate)}',
                color: secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppText.small('Gasto: ${spent.formatted}', fontWeight: FontWeight.w600),
                  ),
                  AppText.subtitle('${progress.purchasedCount} de ${progress.itemCount} comprados', color: secondary),
                ],
              ),
              if (goal != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppText.subtitle(
                  spent > goal
                      ? '${(spent - goal).formatted} acima da meta de ${goal.formatted}'
                      : '${(goal - spent).formatted} abaixo da meta de ${goal.formatted}',
                  color: spent > goal ? context.colors.error : context.semantic.success,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
