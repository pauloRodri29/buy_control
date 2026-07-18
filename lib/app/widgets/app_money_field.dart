import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/money/money_input_formatter.dart';
import 'package:flutter/material.dart';

/// Campo de valor monetário reutilizável: formata como moeda em tempo
/// real (`MoneyInputFormatter`) e sempre expõe/recebe [Money], nunca
/// String/double crus — elimina o parser manual duplicado em cada tela
/// que pede um valor em reais.
class AppMoneyField extends StatefulWidget {
  final Money? initialValue;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<Money> onChanged;

  const AppMoneyField({
    super.key,
    this.initialValue,
    this.label,
    this.hint = 'R\$ 0,00',
    this.errorText,
    required this.onChanged,
  });

  @override
  State<AppMoneyField> createState() => _AppMoneyFieldState();
}

class _AppMoneyFieldState extends State<AppMoneyField> {
  late final _controller = TextEditingController(
    text: widget.initialValue == null || widget.initialValue!.isZero ? '' : widget.initialValue!.formatted,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      keyboardType: TextInputType.number,
      inputFormatters: [MoneyInputFormatter()],
      onChanged: (value) => widget.onChanged(MoneyInputFormatter.parse(value)),
    );
  }
}
