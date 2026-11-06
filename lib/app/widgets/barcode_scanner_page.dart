import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/text_input_dialog.dart';
import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
/// Só aceita códigos de produto válidos (dígito verificador conferido) e
/// ignora o mesmo código por alguns segundos, para não contar duas vezes a
/// mesma embalagem parada na frente da câmera.
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

  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA],
  );

  bool _busy = false;
  String? _lastDigits;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _feedback;
  int _count = 0;

  bool get _continuous => widget.onScanned != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final code = BarcodeParser.parse(raw);
      if (code != null) {
        _handle(code);
        return;
      }
    }
  }

  Future<void> _handle(ScannedCode code) async {
    if (_busy) return;
    final now = DateTime.now();
    if (code.digits == _lastDigits && now.difference(_lastAt) < _repeatCooldown) return;

    _busy = true;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

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
      Get.snackbar('Código inválido', 'Confira os números (o último dígito é de verificação).');
      return;
    }
    _lastDigits = null; // digitado à mão sempre conta
    await _handle(code);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final window = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.38),
      width: size.width * 0.8,
      height: size.width * 0.45,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: AppText.title(widget.title, fontSize: AppFontSizes.fz09),
        actions: [
          IconButton(
            tooltip: 'Lanterna',
            icon: const Icon(LucideIcons.flashlight),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(tooltip: 'Digitar código', icon: const Icon(LucideIcons.keyboard), onPressed: _typeCode),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _CameraError(error: error),
            ),
          ),
          Positioned.fromRect(
            rect: window,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textOnDarkButton, width: 2),
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
                  _Banner(
                    text: _feedback ??
                        (_continuous
                            ? 'Aponte para o código de barras. Cada leitura adiciona o produto.'
                            : 'Aponte para o código de barras.'),
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
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  const _Banner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: AppRadius.borderLg),
      child: AppText(text, textAlign: TextAlign.center, color: AppColors.textOnDarkButton),
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
        child: AppText(message, textAlign: TextAlign.center, color: AppColors.textOnDarkButton),
      ),
    );
  }
}
