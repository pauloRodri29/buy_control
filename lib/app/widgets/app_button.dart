import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.height = 48,
    this.expanded = true,
  });

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 48,
    this.expanded = true,
  }) : variant = AppButtonVariant.danger;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 48,
    this.expanded = true,
  }) : variant = AppButtonVariant.secondary;

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
    }

    final button = Material(
      color: disabled ? background.withValues(alpha: 0.5) : background,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onPressed,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText(
            label,
            fontSize: AppFontSizes.fz08,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
