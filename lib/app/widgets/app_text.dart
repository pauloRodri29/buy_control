import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Texto do app sobre a escala nativa do [TextTheme]:
/// - `AppText(...)` → `bodyLarge`
/// - `AppText.title(...)` → `headlineSmall`
/// - `AppText.subtitle(...)` → `bodySmall` (tom secundário)
///
/// `fontSize`, `fontWeight` e `color` são ajustes pontuais sobre o estilo
/// do tema; sem eles, vale o que o tema define.
class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final int? maxLines;
  final TextAlign textAlign;
  final TextOverflow? overflow;
  final _AppTextKind _kind;

  const AppText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  }) : _kind = _AppTextKind.body;

  const AppText.title(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  }) : _kind = _AppTextKind.title;

  const AppText.subtitle(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow,
  }) : _kind = _AppTextKind.subtitle;

  @override
  Widget build(BuildContext context) {
    final base = switch (_kind) {
      _AppTextKind.body => context.text.bodyLarge,
      _AppTextKind.title => context.text.headlineSmall,
      _AppTextKind.subtitle => context.text.bodySmall,
    };
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: base?.copyWith(fontSize: fontSize, fontWeight: fontWeight, color: color),
    );
  }
}

enum _AppTextKind { body, title, subtitle }
