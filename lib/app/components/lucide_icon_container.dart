import 'package:buy_control/app/constants/app_colors.dart';
import 'package:flutter/material.dart';

class LucideIconContainer extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  const LucideIconContainer({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Icon(icon, size: size, color: color),
    );
  }
}
