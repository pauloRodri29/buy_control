import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Diálogo padrão ([AlertDialog] nativo) para pedir um único texto ao
/// usuário (ex.: nome de um item, código digitado). Devolve o texto sem
/// espaços nas pontas, ou `null` se o usuário cancelar.
class TextInputDialog extends StatefulWidget {
  final String title;
  final String? hint;
  final String confirmLabel;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const TextInputDialog({
    super.key,
    required this.title,
    this.hint,
    this.confirmLabel = 'OK',
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? hint,
    String confirmLabel = 'OK',
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
      ),
    );
  }

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    const compact = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(64, 44)));

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(style: compact, onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr)),
        FilledButton(style: compact, onPressed: _confirm, child: Text(widget.confirmLabel.tr)),
      ],
    );
  }
}
