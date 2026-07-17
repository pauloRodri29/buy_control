import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final int? maxLines;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    super.key,
    this.fontSize = AppFontSizes.fz08,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

  const AppText.title(
    this.text, {
    super.key,
    this.fontSize = AppFontSizes.fz11,
    this.fontWeight = FontWeight.bold,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

  const AppText.subtitle(
    this.text, {
    super.key,
    this.fontSize = AppFontSizes.fz06,
    this.fontWeight = FontWeight.w500,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary(isDark),
      ),
    );
  }
}
