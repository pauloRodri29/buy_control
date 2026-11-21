// Gera os PNGs da marca em assets/brand a partir do AppLogoPainter, o
// mesmo desenho usado nas telas. Rode:
//
//   flutter test tool/brand/render_brand_assets_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/brand/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _render(String path, int size, AppLogoPainter painter, {Color? background}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final canvasSize = Size.square(size.toDouble());
  if (background != null) canvas.drawRect(Offset.zero & canvasSize, Paint()..color = background);
  painter.paint(canvas, canvasSize);
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('gera os assets da marca', (tester) async {
    await tester.runAsync(() async {
      await _loadFont(AppBrand.monoFontFamily, [
        'assets/fonts/jetbrains_mono/JetBrainsMono-Regular.ttf',
        'assets/fonts/jetbrains_mono/JetBrainsMono-Bold.ttf',
      ]);

      // Ícone cheio (iOS, web, desktop e Android antigo): quadrado sem
      // transparência; cada sistema aplica a própria máscara.
      await _render('assets/brand/icon.png', 1024, const AppLogoPainter(cornerRadius: 0, contentScale: 0.62));

      // Ícone adaptativo do Android: o desenho precisa caber no círculo
      // seguro (66 de 108 dp), por isso a escala menor.
      await _render(
        'assets/brand/icon_foreground.png',
        1024,
        const AppLogoPainter(drawBackground: false, contentScale: 0.44),
      );
      await _render(
        'assets/brand/icon_monochrome.png',
        1024,
        const AppLogoPainter(drawBackground: false, contentScale: 0.44, monochrome: Colors.white),
      );

      // Splash nativa: símbolo com fundo arredondado (128 dp em xxxhdpi).
      await _render('assets/brand/splash_mark.png', 512, const AppLogoPainter());

      // Splash do Android 12+: o sistema recorta um círculo de 2/3 do
      // tamanho, então o desenho vai sem fundo e menor.
      await _render(
        'assets/brand/splash_mark_android12.png',
        1152,
        const AppLogoPainter(drawBackground: false, contentScale: 0.42),
      );
    });
  });
}
