import 'dart:async';

import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/widgets/text_input_dialog.dart';
import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// O que fazer com cada código lido no modo contínuo. Pode abrir diálogos
/// usando [context] (a câmera fica pausada enquanto isso). Devolve a
/// mensagem curta mostrada na tela (ex.: "+1 Café 500g") ou `null`.
typedef OnBarcodeScanned = Future<String?> Function(BuildContext context, ScannedCode code);

/// Leitor de código de barras em tela cheia.
///
/// - [scanOnce]: lê um código e volta com ele (ex.: cadastro de produto).
/// - [scanContinuous]: "modo carrinho" — cada leitura chama [OnBarcodeScanned]
///   e a câmera continua aberta até o usuário tocar em "Concluir".
///
/// Só lê códigos **dentro do retângulo** (`scanWindow` do `MobileScanner`);
/// a moldura fica verde enquanto há um código válido nele. Só aceita
/// códigos de produto válidos (dígito verificador conferido) e ignora o
/// mesmo código por alguns segundos, para não contar duas vezes a mesma
/// embalagem parada na frente da câmera.
class BarcodeScannerPage extends StatefulWidget {
  final String title;
  final OnBarcodeScanned? onScanned;

  const BarcodeScannerPage._({required this.title, this.onScanned});

  static Future<ScannedCode?> scanOnce(BuildContext context, {String title = 'Ler código de barras'}) {
    return Navigator.of(context).push<ScannedCode>(
      MaterialPageRoute(builder: (_) => BarcodeScannerPage._(title: title)),
    );
  }

  static Future<void> scanContinuous(
    BuildContext context, {
    required OnBarcodeScanned onScanned,
    String title = 'Escanear produtos',
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => BarcodeScannerPage._(title: title, onScanned: onScanned)),
    );
  }

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  static const _repeatCooldown = Duration(seconds: 3);

  /// Quanto tempo a moldura continua verde depois da última leitura. Como
  /// o leitor detecta a cada ~250 ms, ela fica verde enquanto o código
  /// estiver no retângulo e volta ao normal logo que ele sai.
  static const _detectedHold = Duration(milliseconds: 600);

  /// Pausa curta depois da leitura para o usuário ver a moldura verde
  /// antes da câmera pausar ou da tela fechar.
  static const _confirmDelay = Duration(milliseconds: 350);

  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA],
    // Android: aproxima sozinho quando o código aparece pequeno na imagem.
    autoZoom: true,
  );

  bool _busy = false;
  bool _detected = false;
  Timer? _detectedTimer;
  String? _lastDigits;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _feedback;
  int _count = 0;

  bool get _continuous => widget.onScanned != null;

  @override
  void dispose() {
    _detectedTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Área de leitura, nas coordenadas do próprio preview (abaixo da
  /// AppBar). O mesmo retângulo limita a detecção e é desenhado na tela,
  /// então o que aparece na moldura é exatamente o que é lido.
  static Rect _scanWindowFor(Size size) {
    final width = size.width * 0.8;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.4),
      width: width,
      height: width * 0.5,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final code = BarcodeParser.parse(raw);
      if (code != null) {
        _markDetected();
        _handle(code);
        return;
      }
    }
  }

  void _markDetected() {
    _detectedTimer?.cancel();
    if (!_detected) setState(() => _detected = true);
    _detectedTimer = Timer(_detectedHold, () {
      if (mounted) setState(() => _detected = false);
    });
  }

  Future<void> _handle(ScannedCode code) async {
    if (_busy) return;
    final now = DateTime.now();
    if (code.digits == _lastDigits && now.difference(_lastAt) < _repeatCooldown) return;

    _busy = true;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(_confirmDelay);
    if (!mounted) return;

    if (!_continuous) {
      Navigator.of(context).pop(code);
      return;
    }

    await _controller.pause();
    String? message;
    try {
      if (mounted) message = await widget.onScanned!(context, code);
    } finally {
      // O cooldown conta a partir do fim do tratamento: depois de um
      // diálogo, a mesma embalagem ainda na frente da câmera não é somada.
      _lastDigits = code.digits;
      _lastAt = DateTime.now();
      _busy = false;
      if (mounted) {
        setState(() {
          _detected = false;
          if (message != null) {
            _feedback = message;
            _count++;
          }
        });
        await _controller.start();
      }
    }
  }

  Future<void> _typeCode() async {
    final typed = await TextInputDialog.show(
      context,
      title: 'Digitar código',
      hint: 'Números do código de barras',
      keyboardType: TextInputType.number,
    );
    if (typed == null || typed.isEmpty || !mounted) return;

    final code = BarcodeParser.parse(typed);
    if (code == null) {
      AppFeedback.error('Confira os números (o último dígito é de verificação).', title: 'Código inválido');
      return;
    }
    _lastDigits = null; // digitado à mão sempre conta
    await _handle(code);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final idleColor = Colors.white;
    final detectedColor = context.semantic.success;

    return Scaffold(
      // Fundo do preview da câmera: preto independente do tema.
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Lanterna',
            icon: const Icon(LucideIcons.flashlight),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(tooltip: 'Digitar código', icon: const Icon(LucideIcons.keyboard), onPressed: _typeCode),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final window = _scanWindowFor(constraints.biggest);

          return Stack(
            children: [
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  scanWindow: window,
                  tapToFocus: true,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _CameraError(error: error),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: _detected ? detectedColor : idleColor),
                    duration: const Duration(milliseconds: 150),
                    builder: (context, color, _) => ScanWindowOverlay(
                      controller: _controller,
                      scanWindow: window,
                      borderColor: color ?? idleColor,
                      borderWidth: _detected ? 4 : 2,
                      borderRadius: AppRadius.borderLg,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        color: colors.inverseSurface,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              _feedback ??
                                  (_continuous
                                      ? 'Centralize o código de barras no retângulo. Cada leitura adiciona o produto.'
                                      : 'Centralize o código de barras no retângulo.'),
                              textAlign: TextAlign.center,
                              style: context.text.bodyLarge?.copyWith(color: colors.onInverseSurface),
                            ),
                          ),
                        ),
                      ),
                      if (_continuous) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: _count == 0 ? 'Concluir' : 'Concluir ($_count lidos)',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Sem permissão para usar a câmera. Libere o acesso nas configurações do aparelho, '
            'ou use o botão de teclado para digitar o código.'
        : 'Não foi possível abrir a câmera. Use o botão de teclado para digitar o código.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.text.bodyLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
