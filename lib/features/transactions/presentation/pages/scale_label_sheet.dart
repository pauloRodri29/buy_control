import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/barcode/barcode_parser.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/transactions/presentation/pages/product_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// O número embutido na etiqueta de balança é o preço total ou o peso.
enum ScaleValueMode { price, weight }

class ScaleLabelResult {
  /// Produto cadastrado ao qual a etiqueta pertence (ou `null` = item avulso).
  final ProductEntity? product;

  /// `true` quando o produto foi escolhido agora e a etiqueta ainda precisa
  /// ser vinculada a ele (para as próximas leituras reconhecerem direto).
  final bool linkProduct;

  final String name;
  final ScaleValueMode mode;
  final Money price;
  final double weightKg;

  const ScaleLabelResult({
    required this.product,
    required this.linkProduct,
    required this.name,
    required this.mode,
    required this.price,
    required this.weightKg,
  });
}

/// Confirma uma etiqueta de balança lida: o usuário confere se o número é
/// preço ou peso (pode corrigir), e associa a etiqueta a um produto.
class ScaleLabelSheet extends StatefulWidget {
  final ScannedCode code;
  final ProductEntity? product;

  const ScaleLabelSheet({super.key, required this.code, this.product});

  @override
  State<ScaleLabelSheet> createState() => _ScaleLabelSheetState();
}

class _ScaleLabelSheetState extends State<ScaleLabelSheet> {
  late ProductEntity? _product = widget.product;
  bool _pickedHere = false;
  ScaleValueMode _mode = ScaleValueMode.price;
  late Money _price = Money(widget.code.scaleValue ?? 0);
  late final _weightController = TextEditingController(text: _formatKg((widget.code.scaleValue ?? 0) / 1000));
  final _nameController = TextEditingController();
  String? _error;

  static String _formatKg(double kg) => kg.toStringAsFixed(3).replaceAll('.', ',');

  double get _weightKg => QuantityFormatter.parse(_weightController.text) ?? 0;

  @override
  void dispose() {
    _weightController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final selected = await AppBottomSheet.show<List<ProductEntity>>(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: const ProductPickerSheet(),
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    setState(() {
      _product = selected.first;
      _pickedHere = true;
      _error = null;
    });
  }

  void _confirm() {
    final name = _product?.name ?? _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escolha um produto cadastrado ou informe um nome.');
      return;
    }
    if (_mode == ScaleValueMode.price && _price.cents <= 0) {
      setState(() => _error = 'Informe o preço da etiqueta.');
      return;
    }
    if (_mode == ScaleValueMode.weight && _weightKg <= 0) {
      setState(() => _error = 'Informe o peso da etiqueta.');
      return;
    }
    Navigator.of(context).pop(ScaleLabelResult(
      product: _product,
      linkProduct: _pickedHere,
      name: name,
      mode: _mode,
      price: _price,
      weightKg: _weightKg,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = _product;
    final referencePrice = product?.referencePrice;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title('Etiqueta de balança', fontSize: AppFontSizes.fz09),
          const SizedBox(height: AppSpacing.xs),
          AppText.subtitle('Código ${widget.code.digits}'),
          const SizedBox(height: AppSpacing.lg),
          if (product != null)
            Row(
              children: [
                const Icon(LucideIcons.packageCheck, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppText(product.name, fontWeight: FontWeight.w600)),
                AppButton.text(label: 'Trocar', onPressed: _pickProduct),
              ],
            )
          else ...[
            AppText(
              'Etiqueta ainda não vinculada a um produto. Vincule para o app reconhecer as próximas.',
              color: AppColors.textSecondary(isDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'Vincular a produto cadastrado',
              icon: LucideIcons.link,
              onPressed: _pickProduct,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: _nameController, label: 'Ou só um nome (avulso)', hint: 'Ex.: Patinho moído'),
          ],
          const SizedBox(height: AppSpacing.lg),
          const AppText.subtitle('O número da etiqueta é:'),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<ScaleValueMode>(
            segments: const [
              ButtonSegment(value: ScaleValueMode.price, label: Text('Preço'), icon: Icon(LucideIcons.dollarSign)),
              ButtonSegment(value: ScaleValueMode.weight, label: Text('Peso'), icon: Icon(LucideIcons.weight)),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) => setState(() => _mode = selection.first),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_mode == ScaleValueMode.price)
            AppMoneyField(
              initialValue: _price,
              label: 'Preço total da etiqueta',
              onChanged: (money) => setState(() => _price = money),
            )
          else ...[
            AppTextField(
              controller: _weightController,
              label: 'Peso (kg)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText.subtitle(
              referencePrice == null
                  ? 'Informe o preço por kg depois, na lista de itens.'
                  : 'Estimado: ${(referencePrice * _weightKg).formatted} '
                      '(${referencePrice.formatted}/kg de referência — ajuste depois se mudou).',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(_error!, color: AppColors.error),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Adicionar', onPressed: _confirm),
        ],
      ),
    );
  }
}
