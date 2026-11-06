import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:flutter/material.dart';

enum UnknownBarcodeAction { link, create, standalone }

/// Código lido que nenhum produto cadastrado tem. Só devolve a escolha do
/// usuário; quem chamou executa a ação. Fechar a folha = ignorar a leitura.
class UnknownBarcodeSheet extends StatelessWidget {
  final ScannedCode code;
  const UnknownBarcodeSheet({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    void choose(UnknownBarcodeAction action) => Navigator.of(context).pop(action);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.title('Produto não encontrado', fontSize: AppFontSizes.fz09),
        const SizedBox(height: AppSpacing.xs),
        AppText.subtitle('Código ${code.digits}'),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Cadastrar produto novo', onPressed: () => choose(UnknownBarcodeAction.create)),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'Vincular a produto já cadastrado',
          onPressed: () => choose(UnknownBarcodeAction.link),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'Lançar avulso (sem cadastrar)',
          onPressed: () => choose(UnknownBarcodeAction.standalone),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: AppButton.text(label: 'Ignorar', onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}
