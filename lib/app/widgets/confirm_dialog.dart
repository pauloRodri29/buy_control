import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Diálogo de confirmação padrão ([AlertDialog] nativo) para ações
/// destrutivas: título explícito com o nome do item e um corpo que explica
/// o impacto da ação, nunca apenas "Excluir?".
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.isDestructive = true,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Excluir',
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final confirmStyle = isDestructive
        ? FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError)
        : null;
    // Botões do diálogo mais compactos que os de tela cheia.
    const compact = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(64, 44)));

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(style: compact, onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          style: (confirmStyle ?? const ButtonStyle()).merge(compact),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
