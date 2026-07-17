import 'package:buy_control/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 56,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // boxShadow: AppShadows.floating(isDark),
      ),
      child: Material(
        color: backgroundColor ?? AppColors.accent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor ?? AppColors.textOnDarkButton, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}
