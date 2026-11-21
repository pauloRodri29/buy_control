import 'package:get/get.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Ação do menu ⋮ de um [AppListCard].
class AppListCardAction {
  final String label;
  final VoidCallback onSelected;
  final bool destructive;

  const AppListCardAction(this.label, this.onSelected, {this.destructive = false});
}

/// Item padrão das listas do app (Boxes, Produtos, catálogos...):
///
/// ```
/// ┌────────────────────────────────────┐
/// │ Título                           ⋮ │
/// │ linha secundária (opcional)        │
/// │ R$ 12,00  ← destaque (opcional)    │
/// │ detalhe • detalhe                  │
/// └────────────────────────────────────┘
/// ```
class AppListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? highlight;
  final List<String> details;
  final Widget? leading;
  final VoidCallback? onTap;
  final List<AppListCardAction> actions;

  /// Item inacessível no plano atual: aparece esmaecido, com cadeado e sem
  /// ações. [onTap] continua valendo (normalmente abre o aviso do plano).
  final bool locked;

  const AppListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.highlight,
    this.details = const [],
    this.leading,
    this.onTap,
    this.actions = const [],
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final showActions = actions.isNotEmpty && !locked;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, showActions ? 0 : AppSpacing.md, AppSpacing.md),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: Opacity(
              opacity: locked ? 0.45 : 1,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.bodySmall),
                ],
                if (highlight != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(highlight!, style: text.titleMedium?.copyWith(color: colors.primary)),
                ],
                for (final detail in details) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: text.bodySmall),
                ],
              ],
            ),
            ),
          ),
          if (locked)
            Tooltip(
              message: 'common.lockedPlan'.tr,
              child: Icon(Symbols.lock, size: 20, color: colors.onSurfaceVariant),
            ),
          if (showActions)
            PopupMenuButton<AppListCardAction>(
              tooltip: 'common.moreActions'.tr,
              onSelected: (action) => action.onSelected(),
              itemBuilder: (_) => [
                for (final action in actions)
                  PopupMenuItem(
                    value: action,
                    child: Text(
                      action.label,
                      style: action.destructive ? TextStyle(color: colors.error) : null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
