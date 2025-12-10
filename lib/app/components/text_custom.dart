import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_font_size.dart';

class TextCustom extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final int? maxLines;
  final TextAlign textAlign;
  final double height;
  final TextOverflow? overflow;

  // Construtor principal
  const TextCustom({
    super.key,
    required this.text,
    this.fontSize = AppFontSizes.fz14,
    this.fontWeight = FontWeight.normal,
    this.color = AppColors.primary,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.height = 1.2,
    this.overflow,
  });

  // Construtor nomeado para textos grandes (por exemplo títulos)
  const TextCustom.title(
    this.text, {
    super.key,
    this.fontSize = AppFontSizes.fz14,
    this.fontWeight = FontWeight.bold,
    this.color = AppColors.primary,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.height = 1.3,
    this.overflow,
  });

  // Construtor nomeado para textos pequenos/subtítulos
  const TextCustom.subtitle(
    this.text, {
    super.key,
    this.fontSize = AppFontSizes.fz12,
    this.fontWeight = FontWeight.w500,
    this.color = AppColors.secondary,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.height = 1.2,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        // height: height,
      ),
    );
  }
}
