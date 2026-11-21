import 'dart:async';

import 'package:buy_control/app/brand/app_brand.dart';
import 'package:buy_control/app/routes/pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Abertura do app no estilo terminal: digita `> GastoLog` com o cursor
/// piscando e, abaixo, a frase de apoio. Depois segue para o
/// [Routes.INITIAL] (login ou app, decidido pelo `AuthGate`).
///
/// Um toque pula a animação. Com "remover animações" ligado no aparelho,
/// o texto aparece inteiro de uma vez.
class SplashPage extends StatefulWidget {
  /// Chamado ao fim da abertura. Por padrão, troca para [Routes.INITIAL].
  final VoidCallback? onFinished;

  const SplashPage({super.key, this.onFinished});

  static const typeName = Duration(milliseconds: 95);
  static const typeTagline = Duration(milliseconds: 28);
  static const startDelay = Duration(milliseconds: 250);
  static const pauseBetweenLines = Duration(milliseconds: 250);
  static const hold = Duration(milliseconds: 700);

  /// Duração total da abertura com animação.
  static Duration get totalDuration =>
      startDelay + typeName * AppBrand.name.length + pauseBetweenLines + typeTagline * AppBrand.tagline.length + hold;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _typing = AnimationController(vsync: this, duration: SplashPage.totalDuration);
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  Timer? _reducedMotionTimer;
  bool _finished = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.of(context).disableAnimations) {
      _typing.value = 1;
      _reducedMotionTimer = Timer(const Duration(milliseconds: 900), _finish);
      return;
    }
    _blink.repeat();
    _typing.forward().whenComplete(() {
      if (_typing.isCompleted) _finish();
    });
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
    } else {
      Get.offAllNamed(Routes.INITIAL);
    }
  }

  @override
  void dispose() {
    _reducedMotionTimer?.cancel();
    _typing.dispose();
    _blink.dispose();
    super.dispose();
  }

  /// Quantos caracteres do nome e da frase já foram "digitados" no
  /// instante [elapsed] da abertura.
  (int, int) _typedAt(Duration elapsed) {
    final name = AppBrand.name.length;
    final tagline = AppBrand.tagline.length;

    var t = elapsed - SplashPage.startDelay;
    if (t.isNegative) return (0, 0);

    final nameTime = SplashPage.typeName * name;
    if (t < nameTime) return (t.inMicroseconds ~/ SplashPage.typeName.inMicroseconds, 0);

    t -= nameTime + SplashPage.pauseBetweenLines;
    if (t.isNegative) return (name, 0);

    final typed = t.inMicroseconds ~/ SplashPage.typeTagline.inMicroseconds;
    return (name, typed.clamp(0, tagline));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppBrand.terminal,
      ),
      child: Scaffold(
        backgroundColor: AppBrand.terminal,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_typing, _blink]),
                  builder: (context, _) {
                    final elapsed = SplashPage.totalDuration * _typing.value;
                    final (nameCount, taglineCount) = _typedAt(elapsed);
                    // Cursor aceso na primeira metade de cada piscada e
                    // sempre aceso enquanto digita.
                    final typingName = nameCount > 0 && nameCount < AppBrand.name.length;
                    final typingTagline = taglineCount > 0 && taglineCount < AppBrand.tagline.length;
                    final cursorOn = typingName || typingTagline || _blink.value < 0.5;
                    final cursorOnTagline = nameCount == AppBrand.name.length && taglineCount > 0;

                    return _TerminalText(
                      nameCount: nameCount,
                      taglineCount: taglineCount,
                      cursorVisible: cursorOn,
                      cursorOnTagline: cursorOnTagline,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TerminalText extends StatelessWidget {
  final int nameCount;
  final int taglineCount;
  final bool cursorVisible;
  final bool cursorOnTagline;

  const _TerminalText({
    required this.nameCount,
    required this.taglineCount,
    required this.cursorVisible,
    required this.cursorOnTagline,
  });

  static const _nameStyle = TextStyle(
    fontFamily: AppBrand.monoFontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 34,
    height: 1.2,
    color: Colors.white,
  );

  static const _taglineStyle = TextStyle(
    fontFamily: AppBrand.monoFontFamily,
    fontSize: 15,
    height: 1.4,
    color: AppBrand.terminalMuted,
  );

  @override
  Widget build(BuildContext context) {
    const name = AppBrand.name;
    // "Gasto" em branco e "Log" no verde-petróleo, como no logo.
    const splitAt = 5;
    final typedName = name.substring(0, nameCount);
    final cursor = _Cursor(visible: cursorVisible);

    return Semantics(
      label: '${AppBrand.name}. ${AppBrand.tagline}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: _nameStyle,
              children: [
                const TextSpan(
                  text: '> ',
                  style: TextStyle(color: AppBrand.amber),
                ),
                TextSpan(text: typedName.substring(0, typedName.length.clamp(0, splitAt))),
                if (typedName.length > splitAt)
                  TextSpan(
                    text: typedName.substring(splitAt),
                    style: const TextStyle(color: AppBrand.tealLight),
                  ),
                if (!cursorOnTagline)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: cursor.large(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Reserva a altura da linha para o nome não pular quando ela
          // começa a ser digitada.
          Text.rich(
            TextSpan(
              style: _taglineStyle,
              children: [
                TextSpan(text: AppBrand.tagline.substring(0, taglineCount)),
                if (cursorOnTagline)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: cursor.small(),
                  ),
                const TextSpan(text: '​'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cursor {
  final bool visible;

  const _Cursor({required this.visible});

  Widget large() => _block(width: 18, height: 5);

  Widget small() => _block(width: 9, height: 3);

  Widget _block({required double width, required double height}) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: Container(width: width, height: height, color: AppBrand.amber),
      ),
    );
  }
}
