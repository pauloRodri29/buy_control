import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_dropdown.dart';
import 'package:buy_control/app/widgets/app_money_field.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/transactions/domain/entities/discount_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Seletor de promoção de um item: o usuário escolhe o tipo ("Leve 4 por
/// R$ 10", "Leve 3 pague 2", ...) e preenche só os parâmetros daquele
/// tipo. O valor do desconto em si é calculado por quem usa o widget
/// (`DiscountRule.calculate`), nunca digitado à mão.
class DiscountRuleEditor extends StatefulWidget {
  final DiscountRule? initialRule;
  final ValueChanged<DiscountRule?> onChanged;

  const DiscountRuleEditor({super.key, this.initialRule, required this.onChanged});

  @override
  State<DiscountRuleEditor> createState() => _DiscountRuleEditorState();
}

class _DiscountRuleEditorState extends State<DiscountRuleEditor> {
  static const _none = 'none';

  late DiscountType? _type = widget.initialRule?.type;
  late Money _amount = widget.initialRule?.amount ?? Money.zero;
  late final _percentController = TextEditingController(text: _formatNumber(widget.initialRule?.percent));
  late final _quantityController = TextEditingController(text: _formatInt(widget.initialRule?.quantity));
  late final _payController = TextEditingController(text: _formatInt(widget.initialRule?.payQuantity));

  static String _formatNumber(double? value) {
    if (value == null || value == 0) return '';
    return QuantityFormatter.format(value);
  }

  static String _formatInt(int? value) => value == null || value == 0 ? '' : value.toString();

  @override
  void dispose() {
    _percentController.dispose();
    _quantityController.dispose();
    _payController.dispose();
    super.dispose();
  }

  int _parseInt(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _emit() {
    final type = _type;
    if (type == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(DiscountRule(
      type: type,
      amount: _amount,
      percent: QuantityFormatter.parse(_percentController.text) ?? 0,
      quantity: _parseInt(_quantityController),
      payQuantity: _parseInt(_payController),
    ));
  }

  void _changeType(String? key) {
    setState(() {
      _type = DiscountType.values.where((t) => t.name == key).firstOrNull;
      // Parâmetros de um tipo não fazem sentido em outro: recomeça zerado.
      _amount = Money.zero;
      _percentController.clear();
      _quantityController.clear();
      _payController.clear();
    });
    _emit();
  }

  Widget _intField(TextEditingController controller, String label) {
    return AppTextField(
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _emit(),
    );
  }

  Widget _moneyField(String label) {
    return AppMoneyField(
      // A chave força o campo a recomeçar vazio quando o tipo muda.
      key: ValueKey('money-${_type?.name}'),
      initialValue: _amount,
      label: label,
      onChanged: (money) {
        _amount = money;
        _emit();
      },
    );
  }

  Widget _row(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: b),
      ],
    );
  }

  Widget? _fields() {
    switch (_type) {
      case null:
        return null;
      case DiscountType.fixed:
        return _moneyField('Valor do desconto');
      case DiscountType.percent:
        return AppTextField(
          controller: _percentController,
          label: 'Percentual (%)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _emit(),
        );
      case DiscountType.bundlePrice:
        return _row(_intField(_quantityController, 'Leve (un.)'), _moneyField('Por (total)'));
      case DiscountType.buyXPayY:
        return _row(_intField(_quantityController, 'Leve (un.)'), _intField(_payController, 'Pague (un.)'));
      case DiscountType.wholesale:
        return _row(_intField(_quantityController, 'A partir de (un.)'), _moneyField('Preço de cada'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fields();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdown<String>(
          label: 'Desconto / promoção',
          value: _type?.name ?? _none,
          options: [
            const AppDropdownOption(value: _none, label: 'Sem desconto'),
            ...DiscountType.values.map((t) => AppDropdownOption(value: t.name, label: t.label)),
          ],
          onChanged: _changeType,
        ),
        if (fields != null) ...[
          const SizedBox(height: AppSpacing.sm),
          fields,
        ],
      ],
    );
  }
}
