import 'package:buy_control/app/brand/app_brand.dart';
import 'package:flutter/material.dart';

/// Desenho do símbolo do GastoLog: uma tela de terminal com o **G** e o
/// cursor âmbar (`G_`), e abaixo duas linhas de log, a segunda terminando
/// numa moeda.
///
/// É o mesmo desenho usado nas telas ([AppLogoMark]) e na geração do
/// ícone do app (`tool/brand/render_brand_assets_test.dart`), para que os
/// dois nunca fiquem diferentes.
class AppLogoPainter extends CustomPainter {
  /// Desenha o fundo de terminal arredondado. Desligado no primeiro plano
  /// do ícone adaptativo do Android, cujo fundo é uma camada separada.
  final bool drawBackground;

  /// Raio dos cantos do fundo, em fração do lado.
  final double cornerRadius;

  /// Fração do lado ocupada pelo desenho (o resto é margem).
  final double contentScale;

  /// Se informada, desenha tudo numa cor só (ícone temático do Android 13+).
  final Color? monochrome;

  const AppLogoPainter({
    this.drawBackground = true,
    this.cornerRadius = 0.24,
    this.contentScale = 0.64,
    this.monochrome,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;

    if (drawBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(side * cornerRadius)),
        Paint()..color = AppBrand.terminal,
      );
    }

    final fg = monochrome ?? Colors.white;
    final accent = monochrome ?? AppBrand.amber;
    final muted = monochrome?.withValues(alpha: 0.6) ?? AppBrand.terminalMuted;

    final box = side * contentScale;
    // Altura da letra G (altura de maiúscula) dentro da caixa do desenho.
    final capHeight = box * 0.56;
    // Altura de maiúscula da JetBrains Mono: 730/1000 do tamanho da fonte.
    final fontSize = capHeight / 0.73;

    final glyph = TextPainter(
      text: TextSpan(
        text: 'G',
        style: TextStyle(
          fontFamily: AppBrand.monoFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1,
          color: fg,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final gap = box * 0.04;
    final cursorWidth = box * 0.26;
    final cursorHeight = box * 0.09;
    // Recuo interno da letra à esquerda (~7% do tamanho na JetBrains
    // Mono): o alinhamento usa o desenho visível do G, não a caixa dele.
    final bearing = fontSize * 0.07;
    final rowWidth = glyph.width - bearing + gap + cursorWidth;

    // Altura total: G (capHeight) + duas linhas de log abaixo.
    final lineHeight = box * 0.075;
    final line1Top = capHeight + box * 0.17;
    final line2Top = line1Top + box * 0.15;
    final totalHeight = line2Top + lineHeight;

    final left = (size.width - rowWidth) / 2;
    final top = (size.height - totalHeight) / 2;
    final baseline = top + capHeight;

    final glyphBaseline = glyph.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    glyph.paint(canvas, Offset(left - bearing, baseline - glyphBaseline));

    final cursorLeft = left - bearing + glyph.width + gap;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cursorLeft, baseline - cursorHeight, cursorWidth, cursorHeight),
        Radius.circular(cursorHeight * 0.25),
      ),
      Paint()..color = accent,
    );

    final linePaint = Paint()..color = muted;
    final lineRadius = Radius.circular(lineHeight / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top + line1Top, rowWidth * 0.9, lineHeight), lineRadius),
      linePaint,
    );
    final line2Width = rowWidth * 0.52;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top + line2Top, line2Width, lineHeight), lineRadius),
      linePaint,
    );

    final coinRadius = box * 0.075;
    canvas.drawCircle(
      Offset(left + line2Width + gap * 1.5 + coinRadius, top + line2Top + lineHeight / 2),
      coinRadius,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) =>
      oldDelegate.drawBackground != drawBackground ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.contentScale != contentScale ||
      oldDelegate.monochrome != monochrome;
}

/// Símbolo do app (o `G_` no terminal) no tamanho [size].
class AppLogoMark extends StatelessWidget {
  final double size;

  const AppLogoMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppBrand.name,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: AppLogoPainter()),
      ),
    );
  }
}

/// Nome do app escrito com a identidade da marca: "Gasto" na cor do texto
/// e "Log" na cor principal do tema.
class AppWordmark extends StatelessWidget {
  final double fontSize;

  const AppWordmark({super.key, this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontFamily: AppBrand.fontFamily,
      fontWeight: FontWeight.w800,
      fontSize: fontSize,
      letterSpacing: -0.5,
      height: 1.1,
      color: colors.onSurface,
    );
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Gasto'),
          TextSpan(
            text: 'Log',
            style: TextStyle(color: colors.primary),
          ),
        ],
      ),
      style: style,
      semanticsLabel: AppBrand.name,
    );
  }
}

/// Logo completo: símbolo acima do nome, e a frase de apoio opcional.
class AppLogo extends StatelessWidget {
  final double markSize;
  final bool showTagline;

  const AppLogo({super.key, this.markSize = 72, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: markSize),
        SizedBox(height: markSize * 0.22),
        AppWordmark(fontSize: markSize * 0.42),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            AppBrand.tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
