import 'package:get/get.dart';
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
        AppText.heading('transactions.productNotFound'.tr, ),
        const SizedBox(height: AppSpacing.xs),
        AppText.subtitle('transactions.codeDigits'.trParams({'digits': code.digits})),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'transactions.registerNewProduct'.tr, onPressed: () => choose(UnknownBarcodeAction.create)),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'transactions.linkExistingProduct'.tr,
          onPressed: () => choose(UnknownBarcodeAction.link),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'transactions.addOneOffWithoutRegistering'.tr,
          onPressed: () => choose(UnknownBarcodeAction.standalone),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: AppButton.text(label: 'transactions.ignore'.tr, onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}
