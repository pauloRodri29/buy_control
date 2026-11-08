import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Item de lista selecionável ([ListTile] nativo com `selected`), usado em
/// seleções múltiplas como os filtros dos relatórios.
class SelectableListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingText;
  final bool selected;
  final VoidCallback onTap;

  const SelectableListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListTile(
      selected: selected,
      onTap: onTap,
      dense: true,
      tileColor: colors.surfaceContainerHighest,
      selectedTileColor: colors.primary.withValues(alpha: 0.12),
      leading: Icon(
        selected ? LucideIcons.circleCheck : LucideIcons.circle,
        size: 20,
        color: selected ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(title, style: context.text.titleSmall?.copyWith(color: colors.onSurface)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailingText == null ? null : Text(trailingText!),
    );
  }
}
