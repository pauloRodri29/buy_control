import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/planning/domain/entities/plan_item_entity.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = AppColors.textSecondary(isDark);
    final value = item.estimatedValue;

    return Material(
      color: AppColors.surface(isDark),
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.border(isDark)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: item.isPurchased ? 'Marcar como não comprado' : 'Marcar como comprado',
                icon: Icon(
                  item.isPurchased ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: 20,
                  color: item.isPurchased ? AppColors.success : secondary,
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
                        style: TextStyle(
                          fontSize: AppFontSizes.fz07,
                          fontWeight: FontWeight.w600,
                          color: item.isPurchased ? secondary : AppColors.textPrimary(isDark),
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
                      AppText(
                        value == null || value.isZero ? 'Sem valor' : value.formatted,
                        fontSize: AppFontSizes.fz06,
                        fontWeight: value == null ? FontWeight.normal : FontWeight.bold,
                        color: value == null ? secondary : null,
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<PlanItemAction>(
                icon: Icon(LucideIcons.ellipsisVertical, size: 18, color: secondary),
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
