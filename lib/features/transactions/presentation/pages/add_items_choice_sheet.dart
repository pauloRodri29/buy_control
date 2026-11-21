import 'package:get/get.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';

enum AddItemsChoice { scan, products, standalone }

/// Ponto de entrada do fluxo "Adicionar itens": só devolve a escolha do
/// usuário via `Navigator.pop`, nada é lido ou gravado aqui.
class AddItemsChoiceSheet extends StatelessWidget {
  const AddItemsChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading('common.addItems'.tr, ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'transactions.scanProductsCamera'.tr,
          onPressed: () => Navigator.of(context).pop(AddItemsChoice.scan),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'transactions.selectProducts'.tr,
          onPressed: () => Navigator.of(context).pop(AddItemsChoice.products),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'transactions.oneOffEntry'.tr,
          onPressed: () => Navigator.of(context).pop(AddItemsChoice.standalone),
        ),
      ],
    );
  }
}
