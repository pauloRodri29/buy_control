import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';

/// `text` é o botão sem fundo (ação secundária discreta, ex.: "Cancelar",
/// "Trocar"); por padrão não ocupa a largura toda.
enum AppButtonVariant { primary, secondary, danger, text }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onPressed == null;

    final Color background;
    final Color foreground;
    switch (variant) {
      case AppButtonVariant.primary:
        background = AppColors.accent;
        foreground = AppColors.textOnDarkButton;
        break;
      case AppButtonVariant.secondary:
        background = AppColors.surfaceVariant(isDark);
        foreground = AppColors.textPrimary(isDark);
        break;
      case AppButtonVariant.danger:
        background = AppColors.error;
        foreground = AppColors.textOnDarkButton;
        break;
      case AppButtonVariant.text:
        background = Colors.transparent;
        foreground = AppColors.accent;
        break;
    }
    final effectiveForeground = disabled && variant == AppButtonVariant.text
        ? foreground.withValues(alpha: 0.5)
        : foreground;

    final labelText = AppText(
      label,
      fontSize: AppFontSizes.fz08,
      fontWeight: FontWeight.w600,
      color: effectiveForeground,
    );

    final button = Material(
      color: disabled && variant != AppButtonVariant.text ? background.withValues(alpha: 0.5) : background,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onPressed,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: variant == AppButtonVariant.text ? AppSpacing.sm : AppSpacing.lg,
          ),
          child: icon == null
              ? labelText
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: effectiveForeground),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: labelText),
                  ],
                ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
