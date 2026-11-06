import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// Diálogo padrão para pedir um único texto ao usuário (ex.: nome de um
/// item, código digitado). Mesmo visual do [ConfirmDialog]. Devolve o
/// texto sem espaços nas pontas, ou `null` se o usuário cancelar.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.title(widget.title, fontSize: AppFontSizes.fz09),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _controller,
              hint: widget.hint,
              autofocus: true,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppButton(label: widget.confirmLabel, onPressed: _confirm)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
