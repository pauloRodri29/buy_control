import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_icon_sizes.dart';
import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const AppIcon(this.icon, {super.key, this.size = AppIconSizes.md, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(icon, size: size, color: color ?? AppColors.textPrimary(isDark));
  }
}
