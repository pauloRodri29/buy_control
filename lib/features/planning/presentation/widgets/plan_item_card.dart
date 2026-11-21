import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PlanItemAction { edit, move, delete }

/// Card de um item no kanban: check de "comprado", título, descrição e
/// valor estimado.
class PlanItemCard extends StatelessWidget {
  final PlanItemEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePurchased;
  final ValueChanged<PlanItemAction>? onAction;

  const PlanItemCard({super.key, required this.item, this.onTap, this.onTogglePurchased, this.onAction});

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final value = item.estimatedValue;

    return Material(
      color: context.colors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: item.isPurchased ? 'Marcar como não comprado' : 'Marcar como comprado',
                icon: Icon(
                  item.isPurchased ? Symbols.check_circle : Symbols.radio_button_unchecked,
                  fill: item.isPurchased ? 1 : 0,
                  size: 20,
                  color: item.isPurchased ? context.semantic.success : secondary,
                ),
                onPressed: onTogglePurchased,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall!.copyWith(
                          color: item.isPurchased ? secondary : context.colors.onSurface,
                          decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppText.subtitle(
                          item.description!,
                          color: secondary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      AppText.small(
                        value == null || value.isZero ? 'Sem valor' : value.formatted,
                        
                        fontWeight: value == null ? FontWeight.normal : FontWeight.bold,
                        color: value == null ? secondary : null,
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<PlanItemAction>(
                icon: Icon(Symbols.more_vert, size: 18, color: secondary),
                onSelected: onAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: PlanItemAction.move, child: Text('Mover para…')),
                  PopupMenuItem(value: PlanItemAction.edit, child: Text('Editar')),
                  PopupMenuItem(value: PlanItemAction.delete, child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
