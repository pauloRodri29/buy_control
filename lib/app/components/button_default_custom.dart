import 'package:buy_control/app/components/text_custom.dart';
import 'package:buy_control/app/constants/app_colors.dart';
import 'package:buy_control/app/constants/app_font_size.dart';
import 'package:flutter/material.dart';

class ButtonDefaultCustom extends StatelessWidget {
  final String label;
  final VoidCallback? onClick;
  final Color? backgroundColor;
  final Color? textColor;
  const ButtonDefaultCustom({super.key, required this.label, this.onClick, this.backgroundColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextCustom(
          text: label,
          fontSize: AppFontSizes.fz09,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textOnDarkButton,
        ),
      ),
    );
  }
}
