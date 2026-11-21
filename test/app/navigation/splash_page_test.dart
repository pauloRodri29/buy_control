import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/navigation/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder typed(String text) => find.textContaining(text, findRichText: true);

  Future<void> pumpSplash(WidgetTester tester, {required VoidCallback onFinished, bool reduceMotion = false}) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: MaterialApp(home: SplashPage(onFinished: onFinished)),
      ),
    );
  }

  testWidgets('digita o nome, depois a frase de apoio, e termina', (tester) async {
    var finished = false;
    await pumpSplash(tester, onFinished: () => finished = true);

    expect(typed(AppBrand.name), findsNothing);

    // Logo depois de digitar o nome: a frase ainda não começou.
    await tester.pump(SplashPage.startDelay + SplashPage.typeName * AppBrand.name.length);
    expect(typed(AppBrand.name), findsOneWidget);
    expect(typed(AppBrand.tagline), findsNothing);
    expect(finished, isFalse);

    await tester.pump(SplashPage.totalDuration);
    expect(typed(AppBrand.tagline), findsOneWidget);
    expect(finished, isTrue);
  });

  testWidgets('um toque pula a animação', (tester) async {
    var calls = 0;
    await pumpSplash(tester, onFinished: () => calls++);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(SplashPage));
    expect(calls, 1);

    // O fim natural da animação não chama de novo.
    await tester.pump(SplashPage.totalDuration);
    expect(calls, 1);
  });

  testWidgets('sem animações, mostra tudo de uma vez', (tester) async {
    var finished = false;
    await pumpSplash(tester, onFinished: () => finished = true, reduceMotion: true);
    await tester.pump();

    expect(typed(AppBrand.name), findsOneWidget);
    expect(typed(AppBrand.tagline), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(finished, isTrue);
  });
}
