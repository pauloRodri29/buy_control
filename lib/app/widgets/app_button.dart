import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// `text` é o botão sem fundo (ação secundária discreta, ex.: "Cancelar",
/// "Trocar"); por padrão não ocupa a largura toda.
enum AppButtonVariant { primary, secondary, danger, text }

/// Botão do app sobre os botões nativos do Material:
/// - primary → [FilledButton] (estilo do `filledButtonTheme`)
/// - secondary → [FilledButton] tonal (superfície neutra)
/// - danger → [FilledButton] na cor de erro
/// - text → [TextButton]
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final double height;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.height = 48,
    this.expanded = true,
  });

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = true,
  }) : variant = AppButtonVariant.danger;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 40,
    this.expanded = false,
  }) : variant = AppButtonVariant.text;

  ButtonStyle? _style(ColorScheme colors) {
    final size = WidgetStatePropertyAll(Size(64, height));
    return switch (variant) {
      AppButtonVariant.primary => ButtonStyle(minimumSize: size),
      AppButtonVariant.secondary => FilledButton.styleFrom(
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.onSurface,
          disabledBackgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.5),
        ).copyWith(minimumSize: size),
      AppButtonVariant.danger => FilledButton.styleFrom(
          backgroundColor: colors.error,
          foregroundColor: colors.onError,
          disabledBackgroundColor: colors.error.withValues(alpha: 0.5),
          disabledForegroundColor: colors.onError,
        ).copyWith(minimumSize: size),
      AppButtonVariant.text => ButtonStyle(minimumSize: size),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _style(context.colors);
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final iconWidget = icon == null ? null : Icon(icon, size: 18);

    final Widget button;
    if (variant == AppButtonVariant.text) {
      button = iconWidget == null
          ? TextButton(onPressed: onPressed, style: style, child: text)
          : TextButton.icon(onPressed: onPressed, style: style, icon: iconWidget, label: text);
    } else {
      button = iconWidget == null
          ? FilledButton(onPressed: onPressed, style: style, child: text)
          : FilledButton.icon(onPressed: onPressed, style: style, icon: iconWidget, label: text);
    }

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
